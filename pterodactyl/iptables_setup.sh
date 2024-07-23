#!/bin/bash

# Root????
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check args
if [ -z "$1" ]; then
    echo "Usage: $0 <network-interface>"
    exit 1
fi

INTERFACE=$1

# Docker subnets cuz why not automate it
BRIDGE_SUBNET=$(docker network inspect bridge -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
PTERODACTYL_SUBNET=$(docker network inspect pterodactyl_nw -f '{{range .IPAM.Config}}{{if eq .Subnet "fdba:17c8:6c94::/64"}}{{else}}{{.Subnet}}{{end}}{{end}}')
PTERODACTYL_IPV6_SUBNET=$(docker network inspect pterodactyl_nw -f '{{range .IPAM.Config}}{{if eq .Subnet "fdba:17c8:6c94::/64"}}{{.Subnet}}{{end}}{{end}}')

INTERNAL_NET=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}')

echo "Bridge subnet: ${BRIDGE_SUBNET}"
echo "Pterodactyl subnet: ${PTERODACTYL_SUBNET}"
echo "Pterodactyl IPv6 subnet: ${PTERODACTYL_IPV6_SUBNET}"
echo "Internal net: ${INTERNAL_NET}"

read -p "Is the above information correct? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    echo "Operation aborted."
    exit 1
fi

# Apply the rules like a real G
sudo iptables -I FORWARD -s $BRIDGE_SUBNET -d $INTERNAL_NET -j DROP
sudo iptables -I FORWARD -s $PTERODACTYL_SUBNET -d $INTERNAL_NET -j DROP

sudo ip6tables -I FORWARD -s $PTERODACTYL_IPV6_SUBNET -d $INTERNAL_NET -j DROP

sudo iptables -I INPUT -i docker0 -d $INTERNAL_NET -j DROP
sudo iptables -I INPUT -i pterodactyl0 -d $INTERNAL_NET -j DROP
sudo iptables -I OUTPUT -o docker0 -s $INTERNAL_NET -j DROP
sudo iptables -I OUTPUT -o pterodactyl0 -s $INTERNAL_NET -j DROP

# Save to make sure it's persistent, I don't want to run at each reboot.
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6
