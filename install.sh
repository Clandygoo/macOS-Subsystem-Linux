#!/bin/bash
set -e

# macOS Subsystem for Linux - Installer
# https://github.com/zhangpipi/macOS-Subsystem-Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MSL_HOME="$HOME/macOS-Subsystem-Linux"
LIMA_HOME="$HOME/.lima"
MSL_INSTANCE="msl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_arch() {
    if [[ "$(uname -m)" != "arm64" ]]; then
        error "This project only supports Apple Silicon (M1/M2/M3/M4)."
    fi
    success "Apple Silicon detected."
}

check_macos_version() {
    local version
    version=$(sw_vers -productVersion | cut -d. -f1)
    if [[ "$version" -lt 13 ]]; then
        error "macOS 13 (Ventura) or later is required. Current: macOS $version"
    fi
    success "macOS $version detected."
}

check_disk_space() {
    local available
    available=$(df -g / | tail -1 | awk '{print $4}')
    if [[ "$available" -lt 15 ]]; then
        error "At least 15GB free disk space required. Available: ${available}GB"
    fi
    success "Disk space OK (${available}GB available)."
}

install_homebrew() {
    if command -v brew &>/dev/null; then
        success "Homebrew already installed."
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        success "Homebrew installed."
    fi
}

install_lima() {
    if command -v limactl &>/dev/null; then
        success "Lima already installed."
    else
        info "Installing Lima..."
        brew install lima
        success "Lima installed."
    fi
}

install_gh() {
    if command -v gh &>/dev/null; then
        success "GitHub CLI already installed."
    else
        info "Installing GitHub CLI..."
        brew install gh
        success "GitHub CLI installed."
    fi
}

setup_vm() {
    local instance_dir="$LIMA_HOME/$MSL_INSTANCE"

    if [[ -d "$instance_dir" ]]; then
        warn "VM '$MSL_INSTANCE' already exists. Skipping creation."
        return
    fi

    info "Creating Lima VM instance..."

    # Create instance directory
    mkdir -p "$instance_dir"

    # Copy cloud-init config
    cp "$MSL_HOME/lima/debian.yaml" "$instance_dir/debian.yaml"

    info "Starting VM for first-time setup (this may take a few minutes)..."
    limactl start --name="$MSL_INSTANCE" "$MSL_HOME/lima/debian.yaml" || {
        warn "VM start returned non-zero (this is normal for first setup)."
    }

    success "VM created and started."
}

setup_ntfs() {
    info "Installing ntfs-3g in the VM..."

    limactl shell "$MSL_INSTANCE" -- sudo apt-get update -qq
    limactl shell "$MSL_INSTANCE" -- sudo apt-get install -y -qq ntfs-3g fuse3

    # Create mount points
    limactl shell "$MSL_INSTANCE" -- sudo mkdir -p /mnt/ntfs
    limactl shell "$MSL_INSTANCE" -- sudo mkdir -p /mnt/host

    success "ntfs-3g installed in VM."
}

setup_shell_integration() {
    info "Setting up shell integration..."

    # Add MSL to PATH
    local shell_rc
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.zshrc"
        touch "$shell_rc"
    fi

    # Check if already added
    if ! grep -q "macOS-Subsystem-Linux" "$shell_rc" 2>/dev/null; then
        cat >> "$shell_rc" << 'EOF'

# macOS Subsystem for Linux
export PATH="$HOME/macOS-Subsystem-Linux/scripts:$PATH"
alias msl="$HOME/macOS-Subsystem-Linux/scripts/msl"
alias msl-flash="$HOME/macOS-Subsystem-Linux/scripts/msl-flash"
EOF
        info "Added MSL to PATH in $shell_rc"
    fi

    # Make scripts executable
    chmod +x "$MSL_HOME/scripts/"*.sh
    chmod +x "$MSL_HOME/scripts/msl"
    chmod +x "$MSL_HOME/scripts/msl-flash"

    success "Shell integration complete."
    info "Run 'source $shell_rc' or restart your terminal."
}

print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Usage:"
    echo -e "  ${BLUE}msl start${NC}      Start the Linux VM"
    echo -e "  ${BLUE}msl stop${NC}       Stop the Linux VM"
    echo -e "  ${BLUE}msl shell${NC}      Enter Linux shell"
    echo -e "  ${BLUE}msl mount${NC}      Mount NTFS disk"
    echo -e "  ${BLUE}msl status${NC}     Show VM status"
    echo -e "  ${BLUE}msl-flash${NC}     Qualcomm 9008 EDL flash tool"
    echo ""
    echo "Quick start:"
    echo -e "  ${BLUE}msl start && msl shell${NC}"
    echo ""
    echo "NTFS mount:"
    echo -e "  ${BLUE}msl mount /dev/disk2s1${NC}"
    echo ""
    echo -e "${YELLOW}Note: Restart your terminal or run 'source $shell_rc' first.${NC}"
}

main() {
    echo -e "${BLUE}macOS Subsystem for Linux - Installer${NC}"
    echo ""

    check_arch
    check_macos_version
    check_disk_space
    install_homebrew
    install_lima
    setup_vm
    setup_ntfs
    setup_shell_integration
    print_summary
}

main "$@"
