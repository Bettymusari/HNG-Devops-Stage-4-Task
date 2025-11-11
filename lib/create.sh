#!/bin/bash

# VPC Creation Script
log "Creating VPC: $VPC_NAME with CIDR: $CIDR_BLOCK"

# Validate CIDR format
if ! echo "$CIDR_BLOCK" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$'; then
    error "Invalid CIDR format: $CIDR_BLOCK. Use format: 10.0.0.0/16"
    exit 1
fi

# Extract network prefix (e.g., 10.0 from 10.0.0.0/16)
NETWORK_PREFIX=$(echo $CIDR_BLOCK | cut -d'.' -f1-2)
BRIDGE_NAME="br-${VPC_NAME}"

# Check if VPC already exists
if [ -d "$VPC_DIR/$VPC_NAME" ]; then
    error "VPC $VPC_NAME already exists!"
    exit 1
fi

# Create VPC directory
mkdir -p "$VPC_DIR/$VPC_NAME"

# Step 1: Create Linux Bridge (Virtual Router)
log "Creating bridge: $BRIDGE_NAME"
ip link add name $BRIDGE_NAME type bridge
ip link set $BRIDGE_NAME up

# Don't assign a specific IP here - subnets will add their gateway IPs
# This allows multiple subnets to each have their own gateway on the bridge

# Step 2: Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
log "Enabled IP forwarding"

# Step 3: Create VPC configuration
VPC_CONFIG="$VPC_DIR/$VPC_NAME/config.json"
cat > $VPC_CONFIG << CONFIG_EOF
{
  "name": "$VPC_NAME",
  "cidr": "$CIDR_BLOCK",
  "bridge": "$BRIDGE_NAME",
  "created": "$(date)",
  "subnets": {}
}
CONFIG_EOF

log "VPC $VPC_NAME created successfully!"
log "Bridge: $BRIDGE_NAME (gateway IPs will be added by subnets)"
log "Configuration saved: $VPC_CONFIG"
