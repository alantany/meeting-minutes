#!/bin/bash

# Ollama模型导出脚本
# 用于在内网环境中重新导入模型

echo "🔧 Ollama模型导出工具"
echo "===================="
echo ""

# 创建导出目录
EXPORT_DIR="./ollama-models-export"
mkdir -p "$EXPORT_DIR"

echo "📦 导出Ollama模型..."

# 导出DeepSeek模型
echo "🤖 导出 deepseek-r1:14b..."
if ollama show deepseek-r1:14b > /dev/null 2>&1; then
    echo "正在导出 deepseek-r1:14b 到 $EXPORT_DIR/deepseek-r1-14b.tar..."
    docker save $(docker images --format "table {{.Repository}}:{{.Tag}}" | grep deepseek || echo "ollama/deepseek-r1:14b") > "$EXPORT_DIR/deepseek-r1-14b.tar" 2>/dev/null || {
        echo "⚠️  Docker导出失败，创建模型信息文件..."
        ollama show deepseek-r1:14b > "$EXPORT_DIR/deepseek-r1-14b-info.txt"
        echo "deepseek-r1:14b" > "$EXPORT_DIR/models-to-pull.txt"
    }
    echo "✅ deepseek-r1:14b 导出完成"
else
    echo "❌ deepseek-r1:14b 模型未找到"
fi

# 导出GPT-OSS模型
echo "🤖 导出 gpt-oss:20b..."
if ollama show gpt-oss:20b > /dev/null 2>&1; then
    echo "正在导出 gpt-oss:20b 到 $EXPORT_DIR/gpt-oss-20b.tar..."
    docker save $(docker images --format "table {{.Repository}}:{{.Tag}}" | grep gpt-oss || echo "ollama/gpt-oss:20b") > "$EXPORT_DIR/gpt-oss-20b.tar" 2>/dev/null || {
        echo "⚠️  Docker导出失败，创建模型信息文件..."
        ollama show gpt-oss:20b > "$EXPORT_DIR/gpt-oss-20b-info.txt"
        echo "gpt-oss:20b" >> "$EXPORT_DIR/models-to-pull.txt"
    }
    echo "✅ gpt-oss:20b 导出完成"
else
    echo "❌ gpt-oss:20b 模型未找到"
fi

# 创建导入脚本
cat > "$EXPORT_DIR/import-models.sh" << 'EOF'
#!/bin/bash

echo "🔧 Ollama模型导入工具"
echo "===================="
echo ""

# 检查Ollama是否运行
if ! pgrep -x "ollama" > /dev/null; then
    echo "启动Ollama服务..."
    ollama serve &
    sleep 5
fi

# 如果有tar文件，尝试导入
if [ -f "deepseek-r1-14b.tar" ]; then
    echo "📦 导入 deepseek-r1:14b..."
    docker load < deepseek-r1-14b.tar
fi

if [ -f "gpt-oss-20b.tar" ]; then
    echo "📦 导入 gpt-oss:20b..."
    docker load < gpt-oss-20b.tar
fi

# 如果有模型列表文件，提示用户
if [ -f "models-to-pull.txt" ]; then
    echo "📋 需要重新下载的模型："
    cat models-to-pull.txt
    echo ""
    echo "💡 在有网络的环境中运行以下命令："
    while read -r model; do
        echo "   ollama pull $model"
    done < models-to-pull.txt
fi

echo "✅ 导入完成！"
EOF

chmod +x "$EXPORT_DIR/import-models.sh"

echo ""
echo "📋 导出的内容："
ls -lh "$EXPORT_DIR/"

echo ""
echo "🎉 Ollama模型导出完成！"
echo ""
echo "📝 内网部署说明："
echo "1. 将 '$EXPORT_DIR' 目录复制到内网环境"
echo "2. 在内网环境中运行: ./import-models.sh"
echo "3. 如果导入失败，需要在有网络时重新下载模型"

