#!/bin/bash

#iptables.sh
printf '[!] Starting...\n'
#Check if the script is running with sudo permissions
if [ "$EUID" -ne 0 ]
  then echo "[x] Please run as root\n"
  exit
fi


# Define your hostname and services ips
PUBLIC_HOSTNAME=10.10.10.100
LAN=192.168.100.0/24
SSH_LANIP=192.168.100.9
HTTP_LANIP=192.168.100.3
MAIL_LANIP=192.168.100.9

#Define ports
SSH_PORT=6969
MAIL_PORT=9090

#Lan port
LAN_PORT=net_local

#Cool Functions
spinner() {
    local i sp n
    sp='/-\|'
    n=${#sp}
    printf ' '
    while sleep 0.1; do
        printf "%s\b" "${sp:i++%n:1}"
    done
}

printf '[!] Old Firewall Rules\n'
#iptables -S
printf '[!] Cleaning old firewall rules! '
iptables -F
spinner &
sleep 5
kill "$!" # kill the spinner
printf '\n'
printf '[!] Clean Up Success!\n'
sleep 0.1

#Enables the machine ip forwarding
printf '[!] IP Fordwarding!\n'
sleep 0.1
echo 1 > /proc/sys/net/ipv4/ip_forward
printf '    [o] Enabled Ip Forwarding\n'
sleep 0.1


#Source Nat 
printf '[!] Creating Source nat\n'
iptables -t nat -A POSTROUTING  -o vmbr1 -j MASQUERADE
sleep 0.1
printf '    [o] iptables -t nat -A POSTROUTING  -o vmbr1 -j MASQUERADE\n'

#Destination Nat
printf '[!] Creating Destination nat\n'
iptables -t nat -A PREROUTING -p tcp --dport 443 -i $LAN_PORT -j DNAT --to-destination $HTTP_LANIP #https
printf "    [o] Added Port 443/https for $HTTP_LANIP\n" 
sleep 0.1
iptables -t nat -A PREROUTING -p tcp --dport 80 -i $LAN_PORT -j DNAT --to-destination $HTTP_LANIP #http
printf "    [o] Added Port 80/http for $HTTP_LANI\n"
sleep 0.1
iptables -t nat -A PREROUTING -p tcp --dport $SSH_PORT -i $LAN_PORT -j DNAT --to-destination $SSH_LANIP #ssh
printf "    [o] Added Port $SSH_PORT/ssh for $SSH_LANIP\n"
sleep 0.1
iptables -t nat -A PREROUTING -p tcp --dport $MAIL_PORT -i $LAN_PORT -j DNAT --to-destination $MAIL_LANIP #mail
printf "    [o] Added Port $MAIL_PORT/mail for $MAIL_LANIP\n"
sleep 0.1

#############################
#  IPTABLES CONFIGURATION
#############################
printf '[!] Creating IPTABLES CONFIGURATION\n'
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
printf "    [o] iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\n" 
sleep 0.1
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
printf "    [o] iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\n" 
sleep 0.1
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
printf "    [o] iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT\n" 
sleep 0.1

# Allow localhost traffic
iptables -A INPUT -i lo -j ACCEPT
# Allow OUTPUT traffic in router
#iptables -A OUTPUT -j ACCEPT # Accepts all the output packets from the router
iptables -A OUTPUT -p udp -j ACCEPT # UDP Its the most used protocol 
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT # DNS 
iptables -A OUTPUT -p icmp -j ACCEPT # Pings

# Allow SSH (alternate port)
iptables -A FORWARD -p tcp --dport $SSH_PORT -j LOG --log-level 7 --log-prefix "[-] Accept $SSH_PORT ssh"   #
iptables -A FORWARD -p tcp -d $SSH_LANIP --dport $SSH_PORT -j ACCEPT                                        # ssh
printf "    [o] iptables -A FORWARD -p tcp -d $SSH_LANIP --dport $SSH_PORT -j ACCEPT\n"                     #
sleep 0.1
# Allow web server http (default port)
iptables -A FORWARD -p tcp --dport 80 -j LOG --log-level 7 --log-prefix "[-] Accept 80 HTTP"                #
iptables -A FORWARD -p tcp -d $HTTP_LANIP --dport 80 -j ACCEPT                                              # http
printf "    [o] iptables -A FORWARD -p tcp -d $HTTP_LANIP --dport 80 -j ACCEPT\n"                           #
sleep 0.1
# Allow web server https (default port)
iptables -A FORWARD -p tcp --dport 443 -j LOG --log-level 7 --log-prefix "[-] Accept 443 HTTPS"             #
iptables -A FORWARD -p tcp -d $HTTP_LANIP --dport 443 -j ACCEPT                                             # https
printf "    [o] iptables -A FORWARD -p tcp -d $HTTP_LANIP --dport 443 -j ACCEPT\n"                          #
sleep 0.1
# Allow mail server (alternative port)
iptables -A FORWARD -p tcp --dport $MAIL_PORT -j LOG --log-level 7 --log-prefix "[-] Accept $MAIL_PORT MAIL"#
iptables -A FORWARD -p tcp -d $MAIL_LANIP --dport $MAIL_PORT -j ACCEPT                                      # mail
printf "    [o] iptables -A FORWARD -p tcp -d $MAIL_LANIP --dport $MAIL_PORT -j ACCEPT\n"                   #
sleep 0.1
# Allow ping (default port)
#iptables -A FORWARD -p icmp -j LOG --log-level 7 --log-prefix "[-] Accept ping"                             #
#iptables -A FORWARD -p icmp -j ACCEPT                                                                       # ping
#printf "    [o] iptables -A FORWARD -p icmp -j ACCEPT\n"                                                    #
#sleep 0.1
# Allow DNS (default port)
iptables -A FORWARD -p udp --dport 53 -j LOG --log-level 7 --log-prefix "[-] Accept DNS"                    #
iptables -A FORWARD -p udp --dport 53 -j ACCEPT                                                             # DNS
printf "    [o] iptables -A FORWARD -p udp --dport 53 -j ACCEPT \n"                                         #
sleep 0.1
iptables -A FORWARD -s $LAN -j LOG --log-level 7 --log-prefix "[-] LAN to Outside"                          #
iptables -A FORWARD -s $LAN -j ACCEPT                                                                       # From inside to outside
printf "    [o] iptables -A FORWARD -p udp --dport 53 -j ACCEPT \n"                                         #
sleep 0.1

#############################
#  DEFAULT DENY
#############################

iptables -A FORWARD -d 0.0.0.0/0 -j LOG --log-level 7 --log-prefix "[-] Default Deny"
iptables -A FORWARD -j DROP
printf '[!] Set Up Success!\n'