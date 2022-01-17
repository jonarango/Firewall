#!/bin/bash

#iptables.sh
printf '[!] Starting...\n'
clear
#Check if the script is running with sudo permissions
if [ "$EUID" -ne 0 ]
  then echo "[x] Please run as root\n"
  exit
fi


# Define your hostname and services ips
PUBLIC_HOSTNAME=10.10.10.100
LAN=192.168.100.0/24
WAN=10.10.10.100/24
SSH_LANIP=192.168.100.9
HTTP_LANIP=192.168.100.3
MAIL_LANIP=192.168.100.9

#Define ports
SSH_PORT=6969
MAIL_PORT=9090

#Lan port
WAN_PORT=eth0
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

printf '[O] Github: https://github.com/IMXNOOBX\n'
printf '[!] Old Firewall Rules\n'
#iptables -S
printf '[!] Cleaning old firewall rules! '
iptables -F
spinner &
sleep 3
kill "$!" # kill the spinner
printf '\n'
printf '[!] Clean Up Success!\n'
sleep 0.1

#Enables the machine ip forwarding
printf '[!] IP Fordwarding!\n'
sleep 0.1
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/conf/$WAN_PORT/forwarding
echo 1 > /proc/sys/net/ipv4/conf/$LAN_PORT/forwarding
printf '    [o] Enabled Ip Forwarding\n'
sleep 0.1



#############################
#        Source Nat 
#############################
printf '[!] Creating Source nat\n'
iptables -t nat -A POSTROUTING  -o $WAN_PORT -j MASQUERADE
sleep 0.1
printf '    [o] iptables -t nat -A POSTROUTING  -o $WAN_PORT -j MASQUERADE\n'

#############################
#       Destination Nat
#############################

# Destination Nat #Testing Removed cause apt doesnt work 
printf '[!] Creating Destination nat\n'
iptables -t nat -A PREROUTING -p tcp --dport 443 -i $WAN_PORT -j DNAT --to-destination $HTTP_LANIP #https
printf "    [o] Added Port 443/https for $HTTP_LANIP\n" 
sleep 0.1
iptables -t nat -A PREROUTING -p tcp --dport 80 -i $WAN_PORT -j DNAT --to-destination $HTTP_LANIP #http
printf "    [o] Added Port 80/http for $HTTP_LANI\n"
sleep 0.1
iptables -t nat -A PREROUTING -p tcp --dport $SSH_PORT -i $WAN_PORT -j DNAT --to-destination $SSH_LANIP #ssh
printf "    [o] Added Port $SSH_PORT/ssh for $SSH_LANIP\n"
sleep 0.1
iptables -t nat -A PREROUTING -p tcp --dport $MAIL_PORT -i $WAN_PORT -j DNAT --to-destination $MAIL_LANIP #mail
printf "    [o] Added Port $MAIL_PORT/mail for $MAIL_LANIP\n"
sleep 0.1


#############################
#  IPtables CONFIGURATION
#############################
printf '[!] Creating IPtables CONFIGURATION\n'
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
iptables -A OUTPUT -j ACCEPT # Accepts all the output packets from the router
#iptables -A OUTPUT -p udp -j ACCEPT # UDP Its the most used protocol 
#iptables -A OUTPUT -p udp --dport 53 -j ACCEPT # DNS
#iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT # DNS
#iptables -A OUTPUT -p icmp -j ACCEPT # Pings


iptables -A FORWARD -s $LAN -j LOG --log-prefix "[-] LAN to Outside: "  --log-level 7                           #
iptables -A FORWARD -s $LAN -j ACCEPT                                                                           # From inside to outside
printf "    [o] iptables -A FORWARD -s $LAN -j ACCEPT \n"                                             #
sleep 0.1
# Allow SSH (alternative port)
iptables -A FORWARD -p tcp --dport $SSH_PORT -j LOG --log-prefix "[IPTABLES] Accept p$SSH_PORT ssh: " --log-level 7   #
iptables -A FORWARD -p tcp -d $SSH_LANIP --dport $SSH_PORT -j ACCEPT                                          # ssh
printf "    [o] iptables -A FORWARD -p tcp -d $SSH_LANIP --dport $SSH_PORT -j ACCEPT\n"                       #
sleep 0.1
# Allow web server http (default port)
iptables -A FORWARD -p tcp --dport 80 -j LOG --log-prefix "[IPTABLES] Accept p80 HTTP: " --log-level 7                #
iptables -A FORWARD -p tcp --dport 80 -d $HTTP_LANIP -m limit --limit 25/minute --limit-burst 100 -j ACCEPT   # http (prevent DoS Attacks)
printf "    [o] iptables -A FORWARD -p tcp -d $HTTP_LANIP --dport 80 -j ACCEPT\n"                             #
sleep 0.1
# Allow web server https (default port)
iptables -A FORWARD -p tcp --dport 443 -j LOG --log-prefix "[IPTABLES] Accept p443 HTTPS: " --log-level 7             #
iptables -A FORWARD -p tcp --dport 443 -d $HTTP_LANIP -m limit --limit 25/minute --limit-burst 100 -j ACCEPT  # https
printf "    [o] iptables -A FORWARD -p tcp -d $HTTP_LANIP --dport 443 -j ACCEPT\n"                            #
sleep 0.1
# Allow mail server (alternative port)
iptables -A FORWARD -p tcp --dport $MAIL_PORT -j LOG --log-prefix "[IPTABLES] Accept p$MAIL_PORT MAIL: " --log-level 7 #
iptables -A FORWARD -p tcp -d $MAIL_LANIP --dport $MAIL_PORT -j ACCEPT                                         # mail
printf "    [o] iptables -A FORWARD -p tcp -d $MAIL_LANIP --dport $MAIL_PORT -j ACCEPT\n"                      #
sleep 0.1
# Allow ping (default port)
#iptables -A FORWARD -p icmp -j LOG --log-level 7 --log-prefix "[IPTABLES] Accept ping"                             #
#iptables -A FORWARD -p icmp -j ACCEPT                                                                       # ping
#printf "    [o] iptables -A FORWARD -p icmp -j ACCEPT\n"                                                    #
#sleep 0.1
# Allow DNS (default port)
iptables -A FORWARD -p udp --dport 53 -j LOG --log-prefix "[IPTABLES] Accept DNS: " --log-level 7                      #
iptables -A FORWARD -p udp --dport 53 -j ACCEPT                                                                 # DNS
printf "    [o] iptables -A FORWARD -p udp --dport 53 -j ACCEPT \n"                                             #
sleep 0.1

#############################
#   Clean Old Chains
#############################
printf '[!] Cleaning old Chains '
iptables -X
spinner &
sleep 2
kill "$!" # kill the spinner
printf '\n'

#############################
#   PROTECTIONS             # Check https://github.com/trimstray/iptables-essential for more info
#############################
printf '[!] Setting Up Protections\n'
iptables -N PROTECTIONS
printf "    [o] Created Chain, name: PROTECTIONS\n"  
iptables -A FORWARD -j PROTECTIONS
printf "    [o] Set PROTECTIONS as: FORWARD\n"
iptables -A PROTECTIONS -p tcp ! --syn -m state --state NEW -j DROP    # Kill SYN attacks
printf "    [o] Blocking SYN attacks\n"   
sleep 0.1
iptables -A PROTECTIONS -f -j DROP                                     # Drop fragments
printf "    [o] Blocking Drop Fragments\n"   
sleep 0.1
iptables -A PROTECTIONS -p tcp --tcp-flags ALL ALL -j DROP             # Drop XMAS packets
printf "    [o] Blocking XMAS packets\n"   
sleep 0.1
iptables -A PROTECTIONS -p tcp --tcp-flags ALL NONE -j DROP            # Drop NULL packets
printf "    [o] Blocking NULL packets\n"   
sleep 0.1
iptables -A PROTECTIONS -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
iptables -A PROTECTIONS -j DROP                                        # Protection against port scanning
printf "    [o] Blocking Port scanners\n" 
sleep 0.1

#############################
#   DEFAULT DENY
#############################
printf '[!] Creating logger\n'
iptables -N LOGGING
printf "    [o] Created Chain, name: LOGGING\n"   
sleep 0.1
iptables -A FORWARD -j LOGGING
printf "    [o] Set LOGGING as: FORWARD\n"
iptables -A LOGGING -m limit --limit 5/min -j LOG --log-prefix "[IPTABLES] Dropped: " --log-level 6
printf "    [o] Added LOGGING log limit in: 5/min\n"
iptables -A LOGGING -j DROP
printf '[!] Set Up Success!\n'

printf '[!] Check Firewall logs in: /var/log/syslog\n'
