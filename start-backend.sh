#!/bin/bash

# 启动Meetily后端服务
echo "🚀 启动 Meetily 后端服务..."
echo "================================"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/backend"

# 检查虚拟环境是否存在
if [ ! -d "venv" ]; then
    echo "❌ 虚拟环境不存在，请先运行安装脚本"
    exit 1
fi

# 激活Python虚拟环境
echo "🔧 激活Python虚拟环境..."
source venv/bin/activate

# 检查依赖是否安装
if ! python -c "import app.main" &>/dev/null; then
    echo "❌ 依赖未正确安装，请检查安装过程"
    exit 1
fi

# 启动后端API服务
echo "📡 启动FastAPI服务器..."
echo "🌐 服务地址: http://localhost:8080"
echo "📖 API文档: http://localhost:8080/docs"
echo ""
echo "按 Ctrl+C 停止服务"
echo "================================"

python -m uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload

