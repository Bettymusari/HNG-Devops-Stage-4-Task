#!/bin/bash

# Basic VPC Test Script
# Tests the core functionality of my vpcctl implementation

echo "=== My VPC Basic Test ==="
echo "Testing core VPC functionality..."

# Clean any existing resources
sudo ./bin/vpcctl cleanup

# Test 1: VPC Creation
echo "1. Testing VPC creation..."
sudo ./bin/vpcctl create testvpc 192.168.100.0/24
if [ $? -eq 0 ]; then
    echo "✅ VPC creation test passed"
else
    echo "❌ VPC creation test failed"
    exit 1
fi

# Test 2: Subnet Creation
echo "2. Testing subnet creation..."
sudo ./bin/vpcctl add-subnet testvpc public 192.168.100.0/26 public
if [ $? -eq 0 ]; then
    echo "✅ Subnet creation test passed"
else
    echo "❌ Subnet creation test failed"
    exit 1
fi

# Test 3: List functionality
echo "3. Testing list command..."
sudo ./bin/vpcctl list
if [ $? -eq 0 ]; then
    echo "✅ List command test passed"
else
    echo "❌ List command test failed"
    exit 1
fi

# Test 4: Cleanup
echo "4. Testing cleanup..."
sudo ./bin/vpcctl cleanup
if [ $? -eq 0 ]; then
    echo "✅ Cleanup test passed"
else
    echo "❌ Cleanup test failed"
    exit 1
fi

echo ""
echo "🎉 All basic tests passed! My VPC implementation is working correctly."
