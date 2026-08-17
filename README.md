# macOS Subsystem for Linux

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013+-blue)]()
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon-green)]()

A lightweight Linux subsystem for macOS with native NTFS read/write support, inspired by WSL2.

## Features

- **Lightweight Linux VM** - Debian 12 on Apple Virtualization Framework
- **NTFS Read/Write** - Native NTFS support via ntfs-3g
- **One Command** - Simple `msl` command interface
- **Fast Startup** - Boots in ~10 seconds
- **Low Resource** - 1 CPU, 512MB RAM, 10GB disk (configurable)
- **Shared Folders** - Access macOS files from Linux
- **SSH Access** - Connect via SSH
- **USB Passthrough** - Mount external drives

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon Mac (M1/M2/M3/M4)
- 15GB free disk space
- Internet connection (for first setup)

## Installation

### Quick Install

```bash
git clone https://github.com/zhangpipi/macOS-Subsystem-Linux.git
cd macOS-Subsystem-Linux
chmod +x install.sh
./install.sh
```

### Manual Install

```bash
# Install dependencies
brew install lima

# Create VM
limactl start --name=msl lima/debian.yaml

# Install ntfs-3g in VM
limactl shell msl -- sudo apt-get update
limactl shell msl -- sudo apt-get install -y ntfs-3g
```

## Usage

### Basic Commands

```bash
# Start the VM
msl start

# Enter Linux shell
msl shell

# Stop the VM
msl stop

# Check status
msl status
```

### NTFS Mount

```bash
# Mount an NTFS disk
msl mount /dev/disk2s1

# Access in Linux
msl shell
cd /mnt/ntfs/disk2s1
```

### SSH Access

```bash
# Show SSH info
msl ssh

# Connect via SSH
ssh msl@127.0.0.1 -p 60022
# Password: msl
```

### Install Packages

```bash
# Install a package
msl install vim

# Update all packages
msl update
```

## Configuration

### VM Resources

Edit `lima/debian.yaml` to customize:

```yaml
# CPU cores
cpus: 4

# Memory
memory: "1GiB"

# Disk size
disk: "20GiB"
```

### Shared Folders

By default, your home directory is mounted at `/home/msl/host` in the VM.

## Architecture

```
┌─────────────────────────────────────┐
│           macOS Host                │
│  ┌──────────────────────────────┐   │
│  │   Lima VM (Debian 12)       │   │
│  │   ┌──────────────────────┐   │   │
│  │   │   Linux Shell        │   │   │
│  │   │   - bash/zsh         │   │   │
│  │   │   - ntfs-3g          │   │   │
│  │   │   - common tools     │   │   │
│  │   └──────────────────────┘   │   │
│  │   ┌──────────────────────┐   │   │
│  │   │   virtiofs           │   │   │
│  │   │   - macOS folders    │   │   │
│  │   │   - NTFS disks       │   │   │
│  │   └──────────────────────┘   │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Uninstall

```bash
./uninstall.sh
```

## AI Agent Integration (MSL MCP Server)

MSL 提供 MCP Server，让 AI Agents（如 OpenCode、Claude Desktop 等）可以调用 Linux VM 功能。

### 安装 MCP Server

```bash
cd mcp
npm install
```

### 配置到 OpenCode

在 `~/.config/opencode/opencode.json` 中添加：

```json
{
  "mcp": {
    "msl": {
      "command": "node",
      "args": ["/path/to/macOS-Subsystem-Linux/mcp/server.js"]
    }
  }
}
```

### 可用工具

| 工具 | 描述 | 参数 |
|------|------|------|
| `msl_start` | 启动 VM | - |
| `msl_stop` | 停止 VM | - |
| `msl_status` | 获取状态 | - |
| `msl_exec` | 执行命令 | `command` |
| `msl_python` | 执行 Python | `code` |
| `msl_node` | 执行 Node.js | `code` |
| `msl_install` | 安装软件包 | `package` |
| `msl_mount_ntfs` | 挂载 NTFS | `disk` |
| `msl_list_files` | 列出文件 | `path` |
| `msl_read_file` | 读取文件 | `file` |
| `msl_write_file` | 写入文件 | `file`, `content` |
| `msl_run_python_script` | 运行 Python 脚本 | `filename`, `code` |

### 示例：AI Agent 调用

```javascript
// AI Agent 可以这样调用
await client.callTool({
  name: "msl_python",
  arguments: {
    code: "import sys; print(f'Python {sys.version} on Linux!')"
  }
});

await client.callTool({
  name: "msl_exec",
  arguments: {
    command: "uname -a"
  }
});

await client.callTool({
  name: "msl_install",
  arguments: {
    package: "numpy"
  }
});
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Lima](https://lima-vm.io/) - Linux VMs on macOS
- [ntfs-3g](https://github.com/tuxera/ntfs-3g) - NTFS read/write support
- [Apple Virtualization Framework](https://developer.apple.com/documentation/virtualization)
- [Model Context Protocol](https://modelcontextprotocol.io/) - AI Agent 接口标准
