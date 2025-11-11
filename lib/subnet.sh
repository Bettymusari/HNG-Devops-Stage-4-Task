#!/bin/bash

# Subnet Creation Script
log "Adding subnet $SUBNET_NAME ($SUBNET_CIDR) to VPC $VPC_NAME"

# Validate subnet type
if [ "$SUBNET_TYPE" != "public" ] && [ "$SUBNET_TYPE" != "private" ]; then
    error "Subnet type must be 'public' or 'private', got: $SUBNET_TYPE"
    exit 1
fi

# Check if VPC exists
VPC_CONFIG="$VPC_DIR/$VPC_NAME/config.json"
if [ ! -f "$VPC_CONFIG" ]; then
    error "VPC $VPC_NAME does not exist!"
    exit 1
fi

# Check if subnet already exists
EXISTING_SUBNET=$(jq -r ".subnets.\"$SUBNET_NAME\"" $VPC_CONFIG)
if [ "$EXISTING_SUBNET" != "null" ]; then
    error "Subnet $SUBNET_NAME already exists in VPC $VPC_NAME!"
    exit 1
fi

# Load VPC configuration
BRIDGE_NAME=$(jq -r '.bridge' $VPC_CONFIG)

# Step 1: Create network namespace (virtual subnet)
NS_NAME="ns-${VPC_NAME}-${SUBNET_NAME}"
# Truncate if too long (15 char limit for interfaces)
if [ ${#NS_NAME} -gt 15 ]; then
    NS_NAME="ns-${VPC_NAME:0:5}-${SUBNET_NAME:0:5}"
fi

log "Creating network namespace: $NS_NAME"
ip netns add $NS_NAME

# Step 2: Create veth pair (virtual ethernet cable)
VETH_HOST="veth-${VPC_NAME:0:3}-${SUBNET_NAME:0:3}-h"
VETH_NS="veth-${VPC_NAME:0:3}-${SUBNET_NAME:0:3}-n"
VETH_HOST=${VETH_HOST:0:15}
VETH_NS=${VETH_NS:0:15}

log "Creating veth pair: $VETH_HOST <-> $VETH_NS"
ip link add $VETH_HOST type veth peer name $VETH_NS

# Step 3: Connect one end to bridge
log "Connecting $VETH_HOST to bridge $BRIDGE_NAME"
ip link set $VETH_HOST master $BRIDGE_NAME
ip link set $VETH_HOST up

# Step 4: Connect other end to namespace
log "Connecting $VETH_NS to namespace $NS_NAME"
ip link set $VETH_NS netns $NS_NAME
ip netns exec $NS_NAME ip link set $VETH_NS up

# Step 5: Assign IP address to namespace interface
SUBNET_IP_PREFIX=$(echo $SUBNET_CIDR | cut -d'/' -f1)
HOST_IP="${SUBNET_IP_PREFIX%.*}.2"
GATEWAY_IP="${SUBNET_IP_PREFIX%.*}.1"

log "Assigning IP $HOST_IP/24 to $VETH_NS in namespace"
ip netns exec $NS_NAME ip addr add $HOST_IP/24 dev $VETH_NS
ip netns exec $NS_NAME ip link set lo up

# Step 6: Add gateway IP to bridge for this subnet
log "Adding gateway IP $GATEWAY_IP/24 to bridge $BRIDGE_NAME"
ip addr add $GATEWAY_IP/24 dev $BRIDGE_NAME 2>/dev/null || log "Gateway IP $GATEWAY_IP already exists on bridge"

# Step 7: Add default route through bridge
log "Adding default route via gateway $GATEWAY_IP"
ip netns exec $NS_NAME ip route add default via $GATEWAY_IP

# Step 8: Update VPC configuration
SUBNET_JSON="{\"cidr\": \"$SUBNET_CIDR\", \"type\": \"$SUBNET_TYPE\", \"namespace\": \"$NS_NAME\", \"host_ip\": \"$HOST_IP\", \"gateway_ip\": \"$GATEWAY_IP\", \"veth_host\": \"$VETH_HOST\", \"veth_ns\": \"$VETH_NS\"}"

jq --arg name "$SUBNET_NAME" --argjson subnet "$SUBNET_JSON" \
   '.subnets[$name] = $subnet' $VPC_CONFIG > $VPC_CONFIG.tmp
mv $VPC_CONFIG.tmp $VPC_CONFIG

log "✅ Subnet $SUBNET_NAME created successfully!"
log "Namespace: $NS_NAME"
log "Host IP: $HOST_IP"
log "Gateway: $GATEWAY_IP"
