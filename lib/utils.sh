#!/bin/bash
# Common utility functions for vpcctl

validate_cidr() {
    local cidr=$1
    if ! echo "$cidr" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$'; then
        return 1
    fi
    return 0
}
