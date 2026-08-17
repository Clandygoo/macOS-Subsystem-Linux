#!/bin/bash
# MSL - Uninstaller

set -e

MSL_INSTANCE="msl"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}macOS Subsystem for Linux - Uninstaller${NC}"
echo ""
echo -e "${YELLOW}Warning: This will remove the MSL VM and scripts.${NC}"
read -p "Are you sure? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Stop VM
echo -e "${GREEN}Stopping VM...${NC}"
limactl stop "$MSL_INSTANCE" 2>/dev/null || true

# Delete VM
echo -e "${GREEN}Deleting VM...${NC}"
limactl delete "$MSL_INSTANCE" 2>/dev/null || true

# Remove scripts
echo -e "${GREEN}Removing scripts...${NC}"
rm -rf ~/macOS-Subsystem-Linux

# Remove from PATH
echo -e "${GREEN}Cleaning up PATH...${NC}"
if [[ -f "$HOME/.zshrc" ]]; then
    sed -i '' '/macOS-Subsystem-Linux/d' "$HOME/.zshrc"
fi

echo -e "${GREEN}Uninstall complete.${NC}"
