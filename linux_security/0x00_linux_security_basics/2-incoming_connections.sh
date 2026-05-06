#!/bin/bash

# Firewall rules: Allow only incoming TCP connections on port 80

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo"
   exit 1
fi

# Allow incoming TCP connections on port 80 (IPv4)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
echo "Rules updated"

# Allow incoming TCP connections on port 80 (IPv6)
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
echo "Rules updated (v6)"
