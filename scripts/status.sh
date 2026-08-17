#!/bin/bash
# MSL - Show Status

set -e

MSL_INSTANCE="msl"

BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}MSL Status:${NC}"
limactl status "$MSL_INSTANCE" 2>/dev/null || echo "VM not found."
echo ""
echo -e "${BLUE}Disk usage:${NC}"
limactl shell "$MSL_INSTANCE" -- df -h / 2>/dev/null || true
echo ""
echo -e "${BLUE}Memory:${NC}"
limactl shell "$MSL_INSTANCE" -- free -h 2>/dev/null || true
