#!/bin/bash
# MSL - Update Packages

set -e

MSL_INSTANCE="msl"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}Updating packages...${NC}"
limactl shell "$MSL_INSTANCE" -- sudo apt-get update -qq
limactl shell "$MSL_INSTANCE" -- sudo apt-get upgrade -y -qq
echo -e "${GREEN}Packages updated.${NC}"
