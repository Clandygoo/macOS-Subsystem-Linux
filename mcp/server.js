#!/usr/bin/env node

/**
 * MSL MCP Server
 * 让 AI Agents 可以调用 macOS Subsystem for Linux 功能
 * 
 * 使用方法:
 *   npx @modelcontextprotocol/server-macos-subsystem-linux
 * 
 * 或配置到 opencode.json:
 *   {
 *     "mcp": {
 *       "msl": {
 *         "command": "node",
 *         "args": ["path/to/server.js"]
 *       }
 *     }
 *   }
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync, exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

const MSL_INSTANCE = "msl";

// 执行命令
async function runCommand(command, timeout = 30000) {
  try {
    const { stdout, stderr } = await execAsync(command, { 
      timeout,
      maxBuffer: 1024 * 1024 * 10 
    });
    return { success: true, output: stdout, error: stderr };
  } catch (error) {
    return { success: false, output: error.stdout || "", error: error.message };
  }
}

// 检查 VM 状态
async function checkVMStatus() {
  const result = await runCommand(`limactl list --format json 2>/dev/null`);
  try {
    const instance = JSON.parse(result.output);
    // limactl list --format json 返回单个对象
    if (instance && instance.name === MSL_INSTANCE) {
      return instance.status === "Running";
    }
    // 如果是数组，查找 msl 实例
    if (Array.isArray(instance)) {
      const msl = instance.find(i => i.name === MSL_INSTANCE);
      return msl && msl.status === "Running";
    }
    return false;
  } catch {
    return false;
  }
}

// 创建服务器
const server = new Server(
  {
    name: "macos-subsystem-linux",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// 列出工具
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "msl_start",
        description: "启动 Linux VM",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "msl_stop",
        description: "停止 Linux VM",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "msl_status",
        description: "获取 VM 状态",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "msl_exec",
        description: "在 Linux VM 中执行命令",
        inputSchema: {
          type: "object",
          properties: {
            command: {
              type: "string",
              description: "要执行的 shell 命令",
            },
          },
          required: ["command"],
        },
      },
      {
        name: "msl_python",
        description: "在 Linux VM 中执行 Python 代码",
        inputSchema: {
          type: "object",
          properties: {
            code: {
              type: "string",
              description: "要执行的 Python 代码",
            },
          },
          required: ["code"],
        },
      },
      {
        name: "msl_node",
        description: "在 Linux VM 中执行 Node.js 代码",
        inputSchema: {
          type: "object",
          properties: {
            code: {
              type: "string",
              description: "要执行的 Node.js 代码",
            },
          },
          required: ["code"],
        },
      },
      {
        name: "msl_install",
        description: "在 Linux VM 中安装软件包",
        inputSchema: {
          type: "object",
          properties: {
            package: {
              type: "string",
              description: "要安装的软件包名称",
            },
          },
          required: ["package"],
        },
      },
      {
        name: "msl_mount_ntfs",
        description: "挂载 NTFS 磁盘到 Linux VM",
        inputSchema: {
          type: "object",
          properties: {
            disk: {
              type: "string",
              description: "磁盘路径，如 /dev/disk2s1",
            },
          },
          required: ["disk"],
        },
      },
      {
        name: "msl_list_files",
        description: "列出 Linux VM 中的文件",
        inputSchema: {
          type: "object",
          properties: {
            path: {
              type: "string",
              description: "目录路径",
              default: "/",
            },
          },
          required: [],
        },
      },
      {
        name: "msl_read_file",
        description: "读取 Linux VM 中的文件内容",
        inputSchema: {
          type: "object",
          properties: {
            file: {
              type: "string",
              description: "文件路径",
            },
          },
          required: ["file"],
        },
      },
      {
        name: "msl_write_file",
        description: "写入内容到 Linux VM 中的文件",
        inputSchema: {
          type: "object",
          properties: {
            file: {
              type: "string",
              description: "文件路径",
            },
            content: {
              type: "string",
              description: "要写入的内容",
            },
          },
          required: ["file", "content"],
        },
      },
      {
        name: "msl_run_python_script",
        description: "在 Linux VM 中创建并运行 Python 脚本",
        inputSchema: {
          type: "object",
          properties: {
            filename: {
              type: "string",
              description: "脚本文件名",
            },
            code: {
              type: "string",
              description: "Python 代码",
            },
          },
          required: ["filename", "code"],
        },
      },
      {
        name: "msl_flash_info",
        description: "查看 Qualcomm 9008 EDL 设备信息",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "msl_flash_test",
        description: "测试 EDL 连接",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "msl_flash_dump_gpt",
        description: "读取 GPT 分区表",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "msl_flash_read",
        description: "从 EDL 设备读取分区",
        inputSchema: {
          type: "object",
          properties: {
            partition: {
              type: "string",
              description: "分区名",
            },
            output: {
              type: "string",
              description: "输出文件路径",
            },
          },
          required: ["partition", "output"],
        },
      },
      {
        name: "msl_flash_write",
        description: "向 EDL 设备写入分区",
        inputSchema: {
          type: "object",
          properties: {
            partition: {
              type: "string",
              description: "分区名",
            },
            image: {
              type: "string",
              description: "镜像文件路径",
            },
          },
          required: ["partition", "image"],
        },
      },
      {
        name: "msl_flash_erase",
        description: "擦除 EDL 设备分区",
        inputSchema: {
          type: "object",
          properties: {
            partition: {
              type: "string",
              description: "分区名",
            },
          },
          required: ["partition"],
        },
      },
      {
        name: "msl_flash_mi",
        description: "刷入小米 ROM",
        inputSchema: {
          type: "object",
          properties: {
            rom_dir: {
              type: "string",
              description: "ROM 目录路径",
            },
          },
          required: ["rom_dir"],
        },
      },
      {
        name: "msl_adb",
        description: "执行 ADB 命令",
        inputSchema: {
          type: "object",
          properties: {
            args: {
              type: "string",
              description: "ADB 命令参数",
            },
          },
          required: ["args"],
        },
      },
      {
        name: "msl_fastboot",
        description: "执行 Fastboot 命令",
        inputSchema: {
          type: "object",
          properties: {
            args: {
              type: "string",
              description: "Fastboot 命令参数",
            },
          },
          required: ["args"],
        },
      },
    ],
  };
});

// 处理工具调用
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  // 检查 VM 是否运行（除了 start 和 status 命令）
  if (!["msl_start", "msl_status"].includes(name)) {
    const isRunning = await checkVMStatus();
    if (!isRunning) {
      return {
        content: [
          {
            type: "text",
            text: "VM 未运行。正在启动...",
          },
        ],
      };
    }
  }

  switch (name) {
    case "msl_start": {
      const result = await runCommand(`limactl start ${MSL_INSTANCE} 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.success ? "VM 启动成功" : `启动失败: ${result.error}`,
          },
        ],
      };
    }

    case "msl_stop": {
      const result = await runCommand(`limactl stop ${MSL_INSTANCE} 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.success ? "VM 已停止" : `停止失败: ${result.error}`,
          },
        ],
      };
    }

    case "msl_status": {
      const isRunning = await checkVMStatus();
      if (isRunning) {
        const cpuResult = await runCommand(`limactl shell ${MSL_INSTANCE} -- nproc 2>/dev/null`);
        const memResult = await runCommand(`limactl shell ${MSL_INSTANCE} -- free -m 2>/dev/null | grep Mem`);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "running",
                cpu: cpuResult.output.trim(),
                memory: memResult.output.trim(),
              }, null, 2),
            },
          ],
        };
      } else {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ status: "stopped" }, null, 2),
            },
          ],
        };
      }
    }

    case "msl_exec": {
      const result = await runCommand(
        `limactl shell ${MSL_INSTANCE} -- bash -c '${args.command.replace(/'/g, "'\\''")}' 2>&1`
      );
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_python": {
      // 使用 base64 编码传输代码
      const encoded = Buffer.from(args.code).toString("base64");
      const result = await runCommand(
        `limactl shell ${MSL_INSTANCE} -- bash -c "echo '${encoded}' | base64 -d | python3" 2>&1`
      );
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_node": {
      const encoded = Buffer.from(args.code).toString("base64");
      const result = await runCommand(
        `limactl shell ${MSL_INSTANCE} -- bash -c "echo '${encoded}' | base64 -d | node" 2>&1`
      );
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_install": {
      const result = await runCommand(
        `limactl shell ${MSL_INSTANCE} -- sudo apt-get install -y ${args.package} 2>&1`,
        60000
      );
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_mount_ntfs": {
      // 挂载磁盘
      await runCommand(`diskutil mount ${args.disk} 2>/dev/null`);
      
      // 创建挂载点
      const diskName = args.disk.split("/").pop();
      await runCommand(`limactl shell ${MSL_INSTANCE} -- sudo mkdir -p /mnt/ntfs/${diskName}`);
      
      return {
        content: [
          {
            type: "text",
            text: `NTFS 磁盘已挂载到 /mnt/ntfs/${diskName}`,
          },
        ],
      };
    }

    case "msl_list_files": {
      const result = await runCommand(
        `limactl shell ${MSL_INSTANCE} -- ls -la ${args.path || "/"} 2>&1`
      );
      return {
        content: [
          {
            type: "text",
            text: result.output,
          },
        ],
      };
    }

    case "msl_read_file": {
      const result = await runCommand(
        `limactl shell ${MSL_INSTANCE} -- cat ${args.file} 2>&1`
      );
      return {
        content: [
          {
            type: "text",
            text: result.output,
          },
        ],
      };
    }

    case "msl_write_file": {
      const encoded = Buffer.from(args.content).toString("base64");
      const result = await runCommand(
        `limactl shell ${MSL_INSTANCE} -- bash -c "echo '${encoded}' | base64 -d > ${args.file}" 2>&1`
      );
      return {
        content: [
          {
            type: "text",
            text: result.success ? `文件已写入: ${args.file}` : result.error,
          },
        ],
      };
    }

    case "msl_run_python_script": {
      // 写入脚本
      const encoded = Buffer.from(args.code).toString("base64");
      await runCommand(
        `limactl shell ${MSL_INSTANCE} -- bash -c "echo '${encoded}' | base64 -d > /tmp/${args.filename}"`
      );
      
      // 执行脚本
      const result = await runCommand(
        `limactl shell ${MSL_INSTANCE} -- python3 /tmp/${args.filename} 2>&1`
      );
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_flash_info": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- bash -c "lsusb 2>/dev/null | grep -iE '05c6|2717|2d95|2a70' || echo 'No EDL device found'" 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.output || "No output",
          },
        ],
      };
    }

    case "msl_flash_test": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- edl test 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_flash_dump_gpt": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- edl printgpt --loader=prog_firehose_ddr.elf 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_flash_read": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- edl qread ${args.partition} 1 --loader=prog_firehose_ddr.elf --output=${args.output} 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.success ? `已读取分区 ${args.partition} 到 ${args.output}` : result.error,
          },
        ],
      };
    }

    case "msl_flash_write": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- edl qwrite ${args.partition} ${args.image} --loader=prog_firehose_ddr.elf 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.success ? `已写入分区 ${args.partition}` : result.error,
          },
        ],
      };
    }

    case "msl_flash_erase": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- edl qerase ${args.partition} --loader=prog_firehose_ddr.elf 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.success ? `已擦除分区 ${args.partition}` : result.error,
          },
        ],
      };
    }

    case "msl_flash_mi": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- bash -c "cd ${args.rom_dir} && ls flash_all.sh 2>/dev/null && bash flash_all.sh 2>&1 || echo 'No flash_all.sh found'" 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_adb": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- adb ${args.args} 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    case "msl_fastboot": {
      const result = await runCommand(`limactl shell ${MSL_INSTANCE} -- fastboot ${args.args} 2>&1`);
      return {
        content: [
          {
            type: "text",
            text: result.output || result.error,
          },
        ],
      };
    }

    default:
      return {
        content: [
          {
            type: "text",
            text: `未知工具: ${name}`,
          },
        ],
      };
  }
});

// 启动服务器
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MSL MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
