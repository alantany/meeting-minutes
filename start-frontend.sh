#!/bin/bash

# 启动Meetily前端应用
echo "🚀 启动 Meetily 前端应用..."
echo "================================"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/frontend"

# 检查node_modules是否存在
if [ ! -d "node_modules" ]; then
    echo "❌ 依赖未安装，正在安装..."
    pnpm install
fi

# 设置Rust环境
echo "🔧 设置Rust环境..."
source "$HOME/.cargo/env"

# 检查Rust是否可用
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust未安装或未在PATH中，请检查安装"
    exit 1
fi

# 启动Tauri开发服务器
echo "🖥️  启动Tauri开发环境..."
echo "⏳ 首次启动可能需要几分钟编译..."
echo "🌐 前端地址: http://localhost:3118"
echo ""
echo "按 Ctrl+C 停止服务"
echo "================================"

pnpm tauri dev

