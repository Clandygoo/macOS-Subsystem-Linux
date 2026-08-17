#!/bin/bash
# MSL - Mount NTFS Disk

set -e

MSL_INSTANCE="msl"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo -e "${BLUE}MSL NTFS Mounter${NC}"
    echo ""
    echo "Usage: $0 <disk>"
    echo ""
    echo "Examples:"
    echo "  $0 /dev/disk2s1"
    echo "  $0 /dev/disk4s1"
    echo ""
    echo "Available disks:"
    diskutil list | grep -E "^/dev/disk" | grep -v "disk0" | head -10
}

mount_ntfs() {
    local disk="$1"

    # Get disk info
    local disk_name
    disk_name=$(basename "$disk")

    # Find the mount point
    local mount_point
    mount_point=$(diskutil info "$disk" | grep "Mount Point" | awk '{print $3}')

    if [[ -z "$mount_point" ]]; then
        echo -e "${YELLOW}Disk not mounted. Attempting to mount...${NC}"
        diskutil mount "$disk" || {
            echo -e "${RED}Failed to mount disk.${NC}"
            return 1
        }
        mount_point=$(diskutil info "$disk" | grep "Mount Point" | awk '{print $3}')
    fi

    echo -e "${GREEN}Disk mounted at: $mount_point${NC}"

    # Create mount point in VM
    local vm_mount="/mnt/ntfs/$disk_name"
    limactl shell "$MSL_INSTANCE" -- sudo mkdir -p "$vm_mount"

    # Mount via virtiofs
    echo -e "${BLUE}Mounting in VM...${NC}"
    limactl shell "$MSL_INSTANCE" -- sudo mount -t virtiofs mounted="$vm_mount" 2>/dev/null || true

    echo -e "${GREEN}NTFS disk accessible at: $vm_mount${NC}"
    echo -e "${BLUE}In VM: cd $vm_mount${NC}"
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

mount_ntfs "$1"
