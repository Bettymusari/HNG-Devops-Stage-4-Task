#!/bin/bash

# List all VPCs using jq for proper JSON parsing
log "Listing all VPCs..."

if [ ! -d "$VPC_DIR" ] || [ -z "$(ls -A $VPC_DIR)" ]; then
    echo "No VPCs found."
    exit 0
fi

echo "VPCs:"
echo "-----"

for vpc in $VPC_DIR/*; do
    if [ -f "$vpc/config.json" ]; then
        VPC_NAME=$(basename $vpc)
        CIDR=$(jq -r '.cidr' $vpc/config.json)
        BRIDGE=$(jq -r '.bridge' $vpc/config.json)
        CREATED=$(jq -r '.created' $vpc/config.json)
        SUBNET_COUNT=$(jq -r '.subnets | length' $vpc/config.json)
        
        echo "Name: $VPC_NAME"
        echo "CIDR: $CIDR"
        echo "Bridge: $BRIDGE"
        echo "Subnets: $SUBNET_COUNT"
        echo "Created: $CREATED"
        echo "-----"
    fi
done

# Also show system bridges for verification
echo "System Network Bridges:"
ip -o link show type bridge
