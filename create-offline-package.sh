#!/bin/bash

# 创建完整的内网部署包
echo "📦 创建Meetily内网部署包"
echo "========================"
echo ""

# 创建部署包目录
PACKAGE_DIR="meetily-offline-package"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

echo "🔄 复制项目文件..."

# 复制主要项目文件（排除不必要的文件）
rsync -av \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='target' \
  --exclude='.next' \
  --exclude='out' \
  --exclude='*.log' \
  --exclude='meeting_minutes.db' \
  --exclude='venv' \
  . "$PACKAGE_DIR/"

echo "✅ 项目文件复制完成"

# 复制Whisper模型
echo "🎤 复制Whisper模型..."
if [ -d "models" ]; then
    cp -r models "$PACKAGE_DIR/"
    echo "✅ Whisper模型复制完成"
else
    echo "❌ 未找到models目录"
fi

# 复制Ollama模型导出
echo "🤖 复制Ollama模型导出..."
if [ -d "ollama-models-export" ]; then
    cp -r ollama-models-export "$PACKAGE_DIR/"
    echo "✅ Ollama模型导出复制完成"
else
    echo "❌ 未找到ollama-models-export目录"
fi

# 创建内网部署脚本
cat > "$PACKAGE_DIR/deploy-offline.sh" << 'EOF'
#!/bin/bash

echo "🚀 Meetily内网部署工具"
echo "====================="
echo ""

# 检查系统要求
echo "🔍 检查系统环境..."

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js未安装，请先安装Node.js v18+"
    exit 1
fi

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3未安装，请先安装Python 3.8+"
    exit 1
fi

# 检查Rust
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust未安装，请先安装Rust工具链"
    exit 1
fi

# 检查Ollama
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama未安装，请先安装Ollama"
    exit 1
fi

echo "✅ 系统环境检查通过"
echo ""

# 设置Python后端
echo "🐍 设置Python后端环境..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cd ..
echo "✅ Python后端环境设置完成"

# 设置前端
echo "🌐 设置前端环境..."
cd frontend
if command -v pnpm &> /dev/null; then
    pnpm install
else
    npm install
fi
cd ..
echo "✅ 前端环境设置完成"

# 导入Ollama模型
echo "🤖 导入Ollama模型..."
if [ -d "ollama-models-export" ]; then
    cd ollama-models-export
    ./import-models.sh
    cd ..
else
    echo "⚠️  未找到Ollama模型导出，需要手动配置模型"
fi

echo ""
echo "🎉 内网部署完成！"
echo ""
echo "🚀 启动应用："
echo "1. 启动后端: ./start-backend.sh"
echo "2. 启动前端: ./start-frontend.sh"
echo ""
echo "🌐 访问地址："
echo "- 前端应用: 桌面应用会自动打开"
echo "- 后端API: http://localhost:8080"
echo "- API文档: http://localhost:8080/docs"
EOF

chmod +x "$PACKAGE_DIR/deploy-offline.sh"

# 创建README文件
cat > "$PACKAGE_DIR/README-内网部署.md" << 'EOF'
# Meetily 内网部署包

## 📋 系统要求

### 必需软件
- **Node.js** v18+ 
- **Python** 3.8+
- **Rust** 工具链
- **Ollama** AI模型运行环境

### 硬件要求
- **内存**: 最少16GB（推荐32GB）
- **存储**: 最少20GB可用空间
- **CPU**: 多核处理器（推荐8核+）

## 🚀 快速部署

### 1. 自动部署（推荐）
```bash
./deploy-offline.sh
```

### 2. 手动部署

#### 后端设置
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 前端设置
```bash
cd frontend
pnpm install  # 或 npm install
```

#### Ollama模型导入
```bash
cd ollama-models-export
./import-models.sh
```

## 🔧 启动应用

```bash
# 启动后端（终端1）
./start-backend.sh

# 启动前端（终端2）
./start-frontend.sh
```

## 📂 目录结构

```
meetily-offline-package/
├── backend/                 # Python后端
├── frontend/                # Tauri前端
├── models/                  # Whisper语音识别模型
├── ollama-models-export/    # Ollama AI模型
├── deploy-offline.sh        # 自动部署脚本
├── start-backend.sh         # 后端启动脚本
├── start-frontend.sh        # 前端启动脚本
└── 内网部署指南.md          # 详细部署文档
```

## 🛡️ 安全特性

- ✅ 完全本地运行，无外网连接
- ✅ 数据不离开本地设备
- ✅ 支持完全离线使用
- ✅ 企业级隐私保护

## 🔧 故障排除

### 常见问题
1. **模型加载失败** → 检查models目录权限
2. **Ollama连接失败** → 确认ollama服务运行
3. **前端启动失败** → 检查Node.js和Rust环境
4. **后端启动失败** → 检查Python虚拟环境

### 日志查看
- 后端日志: 终端输出
- 前端日志: 应用内开发者控制台

## 📞 技术支持

如遇到问题，请查看详细的 `内网部署指南.md` 文档。
EOF

# 显示部署包信息
echo ""
echo "📊 部署包统计："
du -sh "$PACKAGE_DIR"
echo ""
echo "📁 部署包内容："
ls -la "$PACKAGE_DIR/"

echo ""
echo "🎉 内网部署包创建完成！"
echo ""
echo "📦 部署包位置: $PACKAGE_DIR"
echo "📝 使用说明: $PACKAGE_DIR/README-内网部署.md"
echo ""
echo "🚀 内网部署步骤："
echo "1. 将整个 '$PACKAGE_DIR' 目录复制到内网环境"
echo "2. 在内网环境中运行: cd $PACKAGE_DIR && ./deploy-offline.sh"
echo "3. 按照提示完成部署和启动"

