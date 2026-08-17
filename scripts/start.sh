#!/bin/bash
# MSL - Start VM

set -e

MSL_INSTANCE="msl"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting MSL...${NC}"

if limactl status "$MSL_INSTANCE" 2>/dev/null | grep -q "Running"; then
    echo -e "${YELLOW}VM is already running.${NC}"
else
    limactl start "$MSL_INSTANCE"
    echo -e "${GREEN}MSL started.${NC}"
fi
