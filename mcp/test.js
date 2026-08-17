#!/usr/bin/env node

/**
 * MSL MCP Server 测试脚本
 */

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

async function test() {
  console.log("Testing MSL MCP Server...\n");

  // 创建客户端
  const transport = new StdioClientTransport({
    command: "node",
    args: ["./server.js"],
  });

  const client = new Client({
    name: "test-client",
    version: "1.0.0",
  });

  try {
    await client.connect(transport);
    console.log("✅ Connected to MSL MCP Server\n");

    // 测试列出工具
    const tools = await client.listTools();
    console.log("📋 Available tools:");
    tools.tools.forEach((tool) => {
      console.log(`  - ${tool.name}: ${tool.description}`);
    });
    console.log("");

    // 测试状态查询
    console.log("🔍 Testing status...");
    const status = await client.callTool({ name: "msl_status", arguments: {} });
    console.log("Status:", status.content[0].text);
    console.log("");

    // 测试执行命令
    console.log("💻 Testing exec...");
    const execResult = await client.callTool({
      name: "msl_exec",
      arguments: { command: "uname -a" },
    });
    console.log("Exec result:", execResult.content[0].text);
    console.log("");

    // 测试 Python 执行
    console.log("🐍 Testing Python...");
    const pythonResult = await client.callTool({
      name: "msl_python",
      arguments: { code: "import sys; print(f'Python {sys.version}')" },
    });
    console.log("Python result:", pythonResult.content[0].text);
    console.log("");

    console.log("✅ All tests passed!");

  } catch (error) {
    console.error("❌ Test failed:", error.message);
  } finally {
    await client.close();
  }
}

test();
