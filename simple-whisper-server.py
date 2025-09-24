#!/usr/bin/env python3
"""
简单的 Whisper 转录服务
用于替代复杂的 Docker 设置，直接在端口 8178 提供转录服务
"""

import os
import sys
import asyncio
import json
import logging
import tempfile
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any

from fastapi import FastAPI, HTTPException, File, UploadFile, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import whisper

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 配置
WHISPER_PORT = 8178
WHISPER_HOST = "127.0.0.1"
MODEL_DIR = Path(__file__).parent / "models"

# 全局变量
whisper_model: Optional[whisper.Whisper] = None

app = FastAPI(
    title="Simple Whisper Transcription Service",
    description="简单的 Whisper 转录服务",
    version="1.0.0"
)

# 添加 CORS 中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def load_whisper_model(model_name: str = "base.en") -> whisper.Whisper:
    """加载 Whisper 模型"""
    global whisper_model
    
    if whisper_model is not None:
        return whisper_model
    
    # 尝试加载本地模型文件
    local_model_path = MODEL_DIR / f"ggml-{model_name}.bin"
    
    try:
        if local_model_path.exists():
            logger.info(f"Loading local Whisper model: {local_model_path}")
            # 对于本地 ggml 文件，我们需要使用 whisper-cpp 或者回退到标准模型
            # 这里我们使用标准的 whisper 库，它会自动下载模型
            whisper_model = whisper.load_model(model_name.replace(".en", ""))
        else:
            logger.info(f"Loading Whisper model: {model_name}")
            whisper_model = whisper.load_model(model_name.replace(".en", ""))
        
        logger.info("Whisper model loaded successfully")
        return whisper_model
        
    except Exception as e:
        logger.error(f"Failed to load Whisper model: {e}")
        # 回退到最小模型
        try:
            logger.info("Falling back to tiny model")
            whisper_model = whisper.load_model("tiny")
            return whisper_model
        except Exception as e2:
            logger.error(f"Failed to load fallback model: {e2}")
            raise HTTPException(status_code=500, detail=f"Failed to load any Whisper model: {e2}")

@app.get("/")
async def health_check():
    """健康检查"""
    return {"status": "ok", "service": "whisper-transcription", "port": WHISPER_PORT}

@app.post("/stream")
async def transcribe_audio_stream(audio: UploadFile = File(...)):
    """转录音频文件 - 匹配前端期待的 /stream 端点"""
    try:
        # 确保模型已加载
        model = load_whisper_model()
        
        # 读取原始音频数据
        content = await audio.read()
        logger.info(f"Received audio data: {len(content)} bytes from {audio.filename}")
        
        # 将字节数据转换为f32样本
        import struct
        samples = []
        for i in range(0, len(content), 4):  # 每个f32占4字节
            if i + 4 <= len(content):
                sample = struct.unpack('<f', content[i:i+4])[0]  # 小端序f32
                samples.append(sample)
        
        logger.info(f"Converted to {len(samples)} audio samples")
        
        # 转换为numpy数组（Whisper需要）
        import numpy as np
        audio_array = np.array(samples, dtype=np.float32)
        
        # 如果音频数据为空，返回空结果
        if len(audio_array) == 0:
            logger.warning("Empty audio data received")
            return {"segments": [], "buffer_size_ms": 0}
        
        try:
            # 使用 Whisper 进行转录
            logger.info(f"Transcribing {len(audio_array)} audio samples")
            result = model.transcribe(audio_array)
            
            # 格式化结果以匹配前端期待的格式
            segments = []
            for segment in result.get("segments", []):
                segments.append({
                    "text": segment.get("text", "").strip(),
                    "t0": segment.get("start", 0.0),
                    "t1": segment.get("end", 0.0)
                })
            
            # 返回前端期待的格式
            response = {
                "segments": segments,
                "buffer_size_ms": 0
            }
            
            logger.info(f"Transcription completed: {len(segments)} segments")
            return response
            
        except Exception as transcribe_error:
            logger.error(f"Transcription failed: {transcribe_error}")
            return {"segments": [], "buffer_size_ms": 0}
                
    except Exception as e:
        logger.error(f"Transcription failed: {e}")
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")

@app.post("/inference")
async def transcribe_audio_inference(file: UploadFile = File(...)):
    """转录音频文件 - 备用端点"""
    return await transcribe_audio_stream(file)

@app.websocket("/stream")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket 流式转录端点（简化版本）"""
    await websocket.accept()
    logger.info("WebSocket connection established")
    
    try:
        while True:
            # 接收音频数据
            data = await websocket.receive_bytes()
            
            # 简化处理：将数据保存为临时文件并转录
            # 实际应用中应该实现真正的流式处理
            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp_file:
                tmp_file.write(data)
                tmp_file_path = tmp_file.name
            
            try:
                model = load_whisper_model()
                result = model.transcribe(tmp_file_path)
                
                # 发送转录结果
                await websocket.send_json({
                    "segments": [
                        {
                            "text": segment.get("text", "").strip(),
                            "t0": segment.get("start", 0.0),
                            "t1": segment.get("end", 0.0)
                        }
                        for segment in result.get("segments", [])
                    ],
                    "buffer_size_ms": 0
                })
                
            finally:
                try:
                    os.unlink(tmp_file_path)
                except:
                    pass
                    
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        logger.info("WebSocket connection closed")

def main():
    """启动服务"""
    logger.info("=" * 50)
    logger.info("🎤 Simple Whisper Transcription Service")
    logger.info("=" * 50)
    logger.info(f"Host: {WHISPER_HOST}")
    logger.info(f"Port: {WHISPER_PORT}")
    logger.info(f"Model Directory: {MODEL_DIR}")
    logger.info("=" * 50)
    
    # 预加载模型
    try:
        logger.info("Pre-loading Whisper model...")
        load_whisper_model()
        logger.info("✅ Model loaded successfully")
    except Exception as e:
        logger.error(f"❌ Failed to load model: {e}")
        logger.info("Service will try to load model on first request")
    
    # 启动服务
    logger.info(f"🚀 Starting server on http://{WHISPER_HOST}:{WHISPER_PORT}")
    logger.info("📖 API docs: http://127.0.0.1:8178/docs")
    logger.info("🔗 WebSocket: ws://127.0.0.1:8178/stream")
    logger.info("=" * 50)
    
    uvicorn.run(
        app,
        host=WHISPER_HOST,
        port=WHISPER_PORT,
        log_level="info"
    )

if __name__ == "__main__":
    main()
