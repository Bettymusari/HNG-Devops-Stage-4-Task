#!/bin/bash

# Firewall / Security Group simulation
log "Applying firewall rules from policy file"

POLICY_FILE="$2"

if [ ! -f "$POLICY_FILE" ]; then
    error "Policy file not found: $POLICY_FILE"
    exit 1
fi

POLICY=$(cat "$POLICY_FILE")
SUBNET_CIDR=$(echo "$POLICY" | jq -r '.subnet')

# Find namespace based on subnet CIDR
NS_NAME=""
for vpc in $VPC_DIR/*; do
    if [ -f "$vpc/config.json" ]; then
        FOUND_NS=$(jq -r --arg cidr "$SUBNET_CIDR" '.subnets[] | select(.cidr==$cidr) | .namespace' "$vpc/config.json")
        if [ -n "$FOUND_NS" ] && [ "$FOUND_NS" != "null" ]; then
            NS_NAME="$FOUND_NS"
            break
        fi
    fi
done

if [ -z "$NS_NAME" ]; then
    error "No namespace found for subnet: $SUBNET_CIDR"
    exit 1
fi

log "Applying rules to namespace: $NS_NAME for subnet: $SUBNET_CIDR"

# Reset firewall rules inside namespace
ip netns exec "$NS_NAME" iptables -F
ip netns exec "$NS_NAME" iptables -X
ip netns exec "$NS_NAME" iptables -Z

# Default deny inbound
ip netns exec "$NS_NAME" iptables -P INPUT DROP
ip netns exec "$NS_NAME" iptables -P FORWARD DROP
ip netns exec "$NS_NAME" iptables -P OUTPUT ACCEPT

# Allow established sessions
ip netns exec "$NS_NAME" iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip netns exec "$NS_NAME" iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback inside namespace
ip netns exec "$NS_NAME" iptables -A INPUT -i lo -j ACCEPT

# Apply ingress rules from JSON policy file
echo "$POLICY" | jq -c '.ingress[]' | while read rule; do
    PORT=$(echo "$rule" | jq -r '.port')
    PROTO=$(echo "$rule" | jq -r '.protocol')
    ACTION=$(echo "$rule" | jq -r '.action')

    if [ "$ACTION" == "allow" ]; then
        ip netns exec "$NS_NAME" iptables -A INPUT -p "$PROTO" --dport "$PORT" -j ACCEPT
        log "✅ ALLOW $PROTO:$PORT in $SUBNET_CIDR"
    else
        ip netns exec "$NS_NAME" iptables -A INPUT -p "$PROTO" --dport "$PORT" -j DROP
        log "❌ DENY $PROTO:$PORT in $SUBNET_CIDR"
    fi
done

log "✅ Firewall rules applied to $NS_NAME"
