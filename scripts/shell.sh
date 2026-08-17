#!/bin/bash
# MSL - Enter Shell

set -e

MSL_INSTANCE="msl"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if ! limactl status "$MSL_INSTANCE" 2>/dev/null | grep -q "Running"; then
    echo -e "${YELLOW}VM is not running. Starting...${NC}"
    limactl start "$MSL_INSTANCE"
fi

echo -e "${GREEN}Entering MSL shell...${NC}"
limactl shell "$MSL_INSTANCE" -- bash
