#!/bin/bash

# VPC Peering Script
VPC1="$1"
VPC2="$2"

log "Creating VPC peering between $VPC1 and $VPC2"

# Check if both VPCs exist
VPC1_CONFIG="$VPC_DIR/$VPC1/config.json"
VPC2_CONFIG="$VPC_DIR/$VPC2/config.json"

if [ ! -f "$VPC1_CONFIG" ] || [ ! -f "$VPC2_CONFIG" ]; then
    error "One or both VPCs do not exist!"
    exit 1
fi

# Get VPC bridges and CIDRs
BRIDGE1=$(jq -r '.bridge' $VPC1_CONFIG)
BRIDGE2=$(jq -r '.bridge' $VPC2_CONFIG)
CIDR1=$(jq -r '.cidr' $VPC1_CONFIG)
CIDR2=$(jq -r '.cidr' $VPC2_CONFIG)

# Create veth pair for peering
PEER1="peer-${VPC1}-${VPC2}"
PEER2="peer-${VPC2}-${VPC1}"

# Truncate if names are too long
PEER1=${PEER1:0:15}
PEER2=${PEER2:0:15}

log "Creating peering veth pair: $PEER1 <-> $PEER2"
ip link add $PEER1 type veth peer name $PEER2

# Connect to respective bridges
ip link set $PEER1 master $BRIDGE1
ip link set $PEER2 master $BRIDGE2

ip link set $PEER1 up
ip link set $PEER2 up

# Remove the isolation firewall rules for these VPCs
log "Removing isolation rules for peering VPCs"
iptables -D FORWARD -s $CIDR1 -d $CIDR2 -j DROP 2>/dev/null || true
iptables -D FORWARD -s $CIDR2 -d $CIDR1 -j DROP 2>/dev/null || true

# Add routes between VPCs
log "Adding routes between VPCs"
ip route add $CIDR2 dev $BRIDGE1 scope link 2>/dev/null || warn "Route $CIDR2 to $BRIDGE1 already exists"
ip route add $CIDR1 dev $BRIDGE2 scope link 2>/dev/null || warn "Route $CIDR1 to $BRIDGE2 already exists"

# Save peering info
PEER_CONFIG="$VPC_DIR/peering.json"
if [ ! -f "$PEER_CONFIG" ]; then
    echo "{}" > $PEER_CONFIG
fi

jq --arg vpc1 "$VPC1" --arg vpc2 "$VPC2" \
   '.[$vpc1] = $vpc2 | .[$vpc2] = $vpc1' $PEER_CONFIG > $PEER_CONFIG.tmp
mv $PEER_CONFIG.tmp $PEER_CONFIG

log "✅ VPC peering established between $VPC1 and $VPC2"
log "Subnets can now communicate across VPCs"
