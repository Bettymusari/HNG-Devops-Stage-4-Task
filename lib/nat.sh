#!/bin/bash

log "Enabling NAT for subnet"

SUBNET_CIDR="$2"

# Detect host interface connected to internet
HOST_INTERFACE=$(ip route | grep default | awk '{print $5}')

if [ -z "$HOST_INTERFACE" ]; then
    error "Could not determine host's internet interface"
    exit 1
fi

log "Using host interface: $HOST_INTERFACE"

# Enable kernel forwarding
sysctl -w net.ipv4.ip_forward=1 >/dev/null

# Allow internet access ONLY for this subnet
iptables -t nat -A POSTROUTING -s "$SUBNET_CIDR" -o "$HOST_INTERFACE" -j MASQUERADE

# Allow traffic forwarding
iptables -A FORWARD -s "$SUBNET_CIDR" -o "$HOST_INTERFACE" -j ACCEPT
iptables -A FORWARD -d "$SUBNET_CIDR" -m state --state RELATED,ESTABLISHED -j ACCEPT

log "✅ NAT enabled only for subnet: $SUBNET_CIDR"

