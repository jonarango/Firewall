#!/bin/bash

#install.sh
printf '[!] Starting...\n'
clear
printf '[O] Github: https://github.com/IMXNOOBX\n'
#Check if the script is running with sudo permissions
if [ "$EUID" -ne 0 ]
  then echo "[x] Please run as root\n"
  exit
fi
sleep 1
printf '[!] Downloading...\n'
wget -O /etc/iptables.sh https://github.com/ITSXNOOBX/Firewall/raw/main/iptables.sh
sleep 1
printf '[!] Seting up automatic startup!...\n'
echo '/etc/iptables.sh' > /etc/rc.local
printf '[!] Done!\n'
printf '[!] Usage: "bash /etc/iptables.sh"\n'
