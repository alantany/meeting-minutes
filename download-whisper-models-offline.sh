#!/bin/bash

# 离线Whisper模型下载脚本
# 此脚本需要在有网络的环境中运行，然后将模型文件复制到内网环境

echo "🔧 离线Whisper模型准备工具"
echo "================================"
echo ""
echo "⚠️  重要说明："
echo "1. 此脚本需要在有外网连接的环境中运行"
echo "2. 下载完成后，将models目录复制到内网环境"
echo "3. 在内网环境中，模型将从本地加载，无需外网连接"
echo ""

# 创建模型目录
MODELS_DIR="./models"
mkdir -p "$MODELS_DIR"

echo "📦 可用的Whisper模型："
echo "1. tiny.en    (~39 MB)  - 最快，精度最低"
echo "2. base.en    (~142 MB) - 平衡选择（推荐）"
echo "3. small.en   (~244 MB) - 更好精度"
echo "4. medium.en  (~769 MB) - 高精度"
echo "5. large-v3   (~1550 MB) - 最高精度"
echo ""

# 下载推荐模型
download_model() {
    local model_name="$1"
    local model_file="$MODELS_DIR/ggml-${model_name}.bin"
    local download_url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${model_name}.bin"
    
    if [ -f "$model_file" ]; then
        echo "✅ 模型已存在: $model_name"
        return 0
    fi
    
    echo "🔄 下载模型: $model_name"
    echo "📍 URL: $download_url"
    
    if curl -L -f \
        --progress-bar \
        --connect-timeout 30 \
        --max-time 3600 \
        --retry 3 \
        --retry-delay 5 \
        --retry-connrefused \
        -o "$model_file" \
        "$download_url"; then
        
        if [ -s "$model_file" ]; then
            local file_size=$(du -h "$model_file" | cut -f1)
            echo "✅ 下载成功: $model_name ($file_size)"
        else
            echo "❌ 下载的文件为空"
            rm -f "$model_file"
            return 1
        fi
    else
        echo "❌ 下载失败: $model_name"
        return 1
    fi
}

# 下载推荐的模型
echo "🚀 开始下载推荐模型..."
download_model "base.en"
download_model "large-v3"

echo ""
echo "🎉 模型下载完成！"
echo ""
echo "📋 内网部署步骤："
echo "1. 将整个 'models' 目录复制到内网环境"
echo "2. 确保模型文件路径正确："
echo "   - ./models/ggml-base.en.bin"
echo "   - ./models/ggml-large-v3.bin"
echo "3. 启动应用时，将自动使用本地模型，无需外网连接"
echo ""
echo "✅ 内网部署准备完成！"

