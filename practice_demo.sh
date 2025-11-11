#!/bin/bash

# VPC Demo Practice Script
# Run this to practice before recording

echo "=== VPC DEMO PRACTICE SESSION ==="
echo "This script helps you practice the 5-minute demo"

# Clean up first
echo "1. Cleaning up..."
sudo ./bin/vpcctl cleanup

echo "2. Creating demo VPC..."
sudo ./bin/vpcctl create demo-vpc 10.200.0.0/16

echo "3. Adding subnets..."
sudo ./bin/vpcctl add-subnet demo-vpc web 10.200.1.0/24 public
sudo ./bin/vpcctl add-subnet demo-vpc db 10.200.2.0/24 private

echo "4. Configuring NAT..."
sudo ./bin/vpcctl nat demo-vpc

echo "5. Testing connectivity..."
echo "Testing web->db:"
sudo ip netns exec ns-demo-web ping -c 2 10.200.2.2
echo "Testing internet from web:"
sudo ip netns exec ns-demo-web ping -c 2 8.8.8.8
echo "Testing internet from db (should fail):"
sudo ip netns exec ns-demo-db ping -c 2 8.8.8.8

echo "6. Starting web server..."
sudo ip netns exec ns-demo-web python3 -m http.server 8080 &
sleep 2
echo "Testing web server:"
sudo ip netns exec ns-demo-web curl -s http://10.200.1.2:8080 >/dev/null && echo "✅ Web server working!"

echo "7. Applying firewall..."
sudo ./bin/vpcctl firewall demo-vpc configs/web-server-policy.json

echo "8. Final cleanup..."
sudo ./bin/vpcctl cleanup

echo "🎉 Practice session complete! Ready for recording?"
