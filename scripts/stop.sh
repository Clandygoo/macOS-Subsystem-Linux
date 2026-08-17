#!/bin/bash
# MSL - Stop VM

set -e

MSL_INSTANCE="msl"

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Stopping MSL...${NC}"
limactl stop "$MSL_INSTANCE"
echo -e "${GREEN}MSL stopped.${NC}"
