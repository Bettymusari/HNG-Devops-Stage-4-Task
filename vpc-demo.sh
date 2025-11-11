#!/bin/bash
# Final demo script — enforces private subnet isolation + NAT only for public subnet (eth0)
# Author: Betty (polished for recording)

set -u
clear

HOST_IF="eth0"                       # <--- your host internet interface (from `ip route`)
VPC_NAME="demo-vpc"
VPC_CIDR="10.100.0.0/16"
PUB_SUBNET_CIDR="10.100.1.0/24"
PRIV_SUBNET_CIDR="10.100.2.0/24"
PUB_NS="ns-demo-vpc-web"
PRIV_NS="ns-demo-vpc-db"

title() {
  echo
  echo "=================================================================="
  echo " $1"
  echo "=================================================================="
}

# Safe cleanup on exit (also runs at normal exit)
cleanup_on_exit() {
  echo
  title "CLEANUP (automatic)"
  sudo ./bin/vpcctl cleanup || true
  sleep 2
  echo "Remaining namespaces (should be empty):"
  ip netns list || true
}
trap cleanup_on_exit EXIT

title "DEMO START — Build AWS-style VPC on Linux (Betty Musari)"
sleep 2

# PRE-CLEAN
title "Pre-cleanup (safe)"
sudo ./bin/vpcctl delete $VPC_NAME >/dev/null 2>&1 || true
sudo ./bin/vpcctl delete peer-vpc >/dev/null 2>&1 || true
sudo ./bin/vpcctl cleanup >/dev/null 2>&1 || true
sleep 3

# STEP 1: Create VPC
title "STEP 1 — Create VPC ($VPC_NAME)"
echo "Narration: 'Creating the VPC with CIDR $VPC_CIDR.'"
sudo ./bin/vpcctl create $VPC_NAME $VPC_CIDR
sleep 8
sudo ./bin/vpcctl list
sleep 6

# STEP 2: Add subnets
title "STEP 2 — Add public & private subnets"
echo "Narration: 'Adding a public subnet for web and a private subnet for DB.'"
sudo ./bin/vpcctl add-subnet $VPC_NAME web 10.100.1.0/24 public
sleep 6
sudo ./bin/vpcctl add-subnet $VPC_NAME db 10.100.2.0/24 private
sleep 8
echo "Namespaces created:"
ip netns list
sleep 6

# STEP 3: Internal connectivity test
title "STEP 3 — Internal connectivity (web -> db)"
echo "Narration: 'Confirming internal connectivity inside the VPC.'"
sudo ip netns exec $PUB_NS ping -c 3 10.100.2.2 || true
sleep 6

# STEP 4: Apply firewall (security group simulation)
title "STEP 4 — Apply firewall rules (security groups)"
echo "Narration: 'Applying JSON security policy to the public subnet namespace.'"
sudo ./bin/vpcctl firewall $VPC_NAME configs/web-server-policy.json
sleep 6

echo "Show firewall rules (public namespace INPUT chain):"
sudo ip netns exec $PUB_NS iptables -L INPUT -n || true
sleep 6

# STEP 5: Enforce private subnet isolation BEFORE NAT
title "STEP 5 — Enforce private subnet isolation (DROP outbound)"
echo "Narration: 'Enforcing private subnet isolation: blocking outbound traffic from the private namespace.'"
# Allow loopback and established first, then insert DROP for outbound to internet
sudo ip netns exec $PRIV_NS iptables -F
sudo ip netns exec $PRIV_NS iptables -P INPUT ACCEPT
sudo ip netns exec $PRIV_NS iptables -P FORWARD ACCEPT
sudo ip netns exec $PRIV_NS iptables -P OUTPUT ACCEPT
# Allow loopback
sudo ip netns exec $PRIV_NS iptables -A OUTPUT -o lo -j ACCEPT
# Allow DNS (optional) — comment out if you want stricter block:
# sudo ip netns exec $PRIV_NS iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
# Block all other outbound IP traffic to the internet
sudo ip netns exec $PRIV_NS iptables -A OUTPUT -d 0.0.0.0/0 -j DROP
sleep 4
echo "Check: private namespace OUTPUT policy and rules:"
sudo ip netns exec $PRIV_NS iptables -L OUTPUT -n || true
sleep 6

# STEP 6: Enable NAT only for public subnet
title "STEP 6 — Enable NAT only for PUBLIC subnet ($PUB_SUBNET_CIDR) on $HOST_IF"
echo "Narration: 'Configuring NAT only for the public subnet so private remains isolated.'"
# First call vpcctl nat (it may add general rules)
sudo ./bin/vpcctl nat $VPC_NAME || true
sleep 3

# Remove any broad MASQUERADE for whole VPC CIDR if present
if sudo iptables -t nat -C POSTROUTING -s "$VPC_CIDR" -o "$HOST_IF" -j MASQUERADE 2>/dev/null; then
  echo "Removing broad MASQUERADE for $VPC_CIDR"
  sudo iptables -t nat -D POSTROUTING -s "$VPC_CIDR" -o "$HOST_IF" -j MASQUERADE || true
fi

# Add MASQUERADE only for public subnet
if ! sudo iptables -t nat -C POSTROUTING -s "$PUB_SUBNET_CIDR" -o "$HOST_IF" -j MASQUERADE 2>/dev/null; then
  sudo iptables -t nat -A POSTROUTING -s "$PUB_SUBNET_CIDR" -o "$HOST_IF" -j MASQUERADE
fi

# Ensure forwarding rules for public subnet
sudo iptables -C FORWARD -s "$PUB_SUBNET_CIDR" -o "$HOST_IF" -j ACCEPT 2>/dev/null || \
  sudo iptables -A FORWARD -s "$PUB_SUBNET_CIDR" -o "$HOST_IF" -j ACCEPT
sudo iptables -C FORWARD -d "$PUB_SUBNET_CIDR" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
  sudo iptables -A FORWARD -d "$PUB_SUBNET_CIDR" -m state --state RELATED,ESTABLISHED -j ACCEPT

sleep 6

# STEP 7: Test internet behavior
title "STEP 7 — Internet behavior test"
echo "Narration: 'Public subnet should reach the internet; private should not.'"

echo "Public subnet ping (should SUCCEED):"
sudo ip netns exec $PUB_NS ping -c 3 8.8.8.8 || true
sleep 6

echo "Private subnet ping (should FAIL):"
if sudo ip netns exec $PRIV_NS ping -c 3 8.8.8.8 >/dev/null 2>&1; then
  echo "❌ Private subnet incorrectly has internet access"
else
  echo "✅ Private subnet correctly blocked from internet"
fi
sleep 6

# STEP 8: Deploy web server quietly
title "STEP 8 — Deploy web server in public subnet (background)"
sudo ip netns exec $PUB_NS python3 -m http.server 8080 >/dev/null 2>&1 &
WEBSERVER_PID=$!
sleep 6

echo "Test web server (public namespace):"
sudo ip netns exec $PUB_NS curl -s http://10.100.1.2:8080 | head -n 4 || true
sleep 6

# STEP 9: Create peer-vpc and peer
title "STEP 9 — Create peer-vpc and peer with demo-vpc"
sudo ./bin/vpcctl create peer-vpc 10.200.0.0/16
sleep 6
sudo ./bin/vpcctl add-subnet peer-vpc app 10.200.1.0/24 public
sleep 6
sudo ./bin/vpcctl peer $VPC_NAME peer-vpc
sleep 10

echo "Cross-VPC ping test (web -> peer app):"
sudo ip netns exec $PUB_NS ping -c 3 10.200.1.2 || true
sleep 8

# STEP 10: Final cleanup (explicit) — trap will also run
title "STEP 10 — Final cleanup"
sudo ./bin/vpcctl cleanup || true
sleep 5

echo
title "DEMO COMPLETE — Good luck with submission!"
sleep 2

# remove trap and exit normally
trap - EXIT
exit 0

