#!/bin/bash

# vpcctl Setup Script
# This script installs dependencies for my VPC project

echo "=== Setting up vpcctl VPC Project ==="
echo "This will install required dependencies..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo: sudo ./setup.sh"
    exit 1
fi

# Detect package manager
if command -v apt > /dev/null; then
    echo "Detected apt package manager (Ubuntu/Debian)"
    PM="apt"
elif command -v yum > /dev/null; then
    echo "Detected yum package manager (RHEL/CentOS)"
    PM="yum"
else
    echo "Error: Could not detect package manager"
    exit 1
fi

# Update package lists
echo "Updating package lists..."
$PM update

# Install required packages
echo "Installing required packages..."

if [ "$PM" = "apt" ]; then
    $PM install -y iproute2 iptables bridge-utils jq python3 curl netcat-openbsd
elif [ "$PM" = "yum" ]; then
    $PM install -y iproute iptables bridge-utils jq python3 curl nc
fi

# Verify installations
echo "Verifying installations..."

for tool in ip iptables bridge jq python3 curl nc; do
    if command -v $tool > /dev/null; then
        echo "✅ $tool is installed"
    else
        echo "❌ $tool is missing"
    fi
done

# Make vpcctl executable
chmod +x bin/vpcctl

echo ""
echo "=== Setup Complete! ==="
echo "You can now use my vpcctl tool:"
echo "  sudo ./bin/vpcctl create myvpc 10.0.0.0/16"
echo "  sudo ./bin/vpcctl add-subnet myvpc public 10.0.1.0/24 public"
echo "  sudo ./bin/vpcctl cleanup"
echo ""
echo "See README.md for full usage instructions."
