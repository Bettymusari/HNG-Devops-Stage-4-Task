#!/bin/bash

# Complete Cleanup Script
log "🧹 Cleaning up ALL VPC resources completely..."

# Remove all VPC directories and configurations
if [ -d "$VPC_DIR" ]; then
    for vpc in $VPC_DIR/*; do
        if [ -f "$vpc/config.json" ]; then
            VPC_NAME=$(basename $vpc)
            BRIDGE_NAME=$(jq -r '.bridge' $vpc/config.json 2>/dev/null || echo "")
            
            log "Cleaning up VPC: $VPC_NAME"
            
            # Delete all subnets (namespaces)
            SUBNETS=$(jq -r '.subnets | keys[]' $vpc/config.json 2>/dev/null)
            for subnet in $SUBNETS; do
                NS_NAME=$(jq -r ".subnets.\"$subnet\".namespace" $vpc/config.json 2>/dev/null)
                VETH_HOST=$(jq -r ".subnets.\"$subnet\".veth_host" $vpc/config.json 2>/dev/null)
                
                # Delete namespace (force delete)
                if [ -n "$NS_NAME" ]; then
                    ip netns delete "$NS_NAME" 2>/dev/null && log "  Deleted namespace: $NS_NAME" || log "  Namespace already deleted: $NS_NAME"
                fi
                
                # Delete veth interface (force delete both ends)
                if [ -n "$VETH_HOST" ]; then
                    ip link delete "$VETH_HOST" 2>/dev/null && log "  Deleted veth: $VETH_HOST" || log "  Veth already deleted: $VETH_HOST"
                fi
            done
            
            # Delete bridge (force delete)
            if [ -n "$BRIDGE_NAME" ]; then
                ip link delete "$BRIDGE_NAME" 2>/dev/null && log "  Deleted bridge: $BRIDGE_NAME" || log "  Bridge already deleted: $BRIDGE_NAME"
            fi
        fi
    done
    
    # Remove VPC directory
    rm -rf $VPC_DIR
    log "Removed VPC directory: $VPC_DIR"
fi

# Clean up ALL peering interfaces (aggressive approach)
log "Cleaning up ALL peering interfaces..."
for iface in $(ip link show | awk -F: '{print $2}' | awk '{print $1}' | grep -E "^peer-" | sed 's/@.*//'); do
    if [ -n "$iface" ]; then
        ip link delete "$iface" 2>/dev/null && log "Deleted peering interface: $iface" || log "Peering interface already deleted: $iface"
    fi
done

# Clean up ALL orphaned veth interfaces
log "Cleaning up ALL orphaned veth interfaces..."
for iface in $(ip link show | awk -F: '{print $2}' | awk '{print $1}' | grep -E "^veth-" | sed 's/@.*//'); do
    if [ -n "$iface" ]; then
        ip link delete "$iface" 2>/dev/null && log "Deleted veth interface: $iface" || log "Veth interface already deleted: $iface"
    fi
done

# Clean up ALL VPC bridges (double check)
log "Cleaning up ALL VPC bridges..."
for iface in $(ip link show | awk -F: '{print $2}' | awk '{print $1}' | grep -E "^br-"); do
    if [ -n "$iface" ]; then
        ip link delete "$iface" 2>/dev/null && log "Deleted bridge: $iface" || log "Bridge already deleted: $iface"
    fi
done

# Clean up iptables rules related to our VPCs
log "Cleaning up iptables rules..."
iptables-save | grep -vE "10.0.0.0/16|10.1.0.0/16" | iptables-restore 2>/dev/null || true

log "✅ COMPLETE cleanup finished! All VPC resources should be removed."
