@echo off
chcp 65001 >nul
title Meetily 后端服务

echo 🚀 启动 Meetily 后端服务...
echo ================================

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%backend"

REM 检查虚拟环境是否存在
if not exist "venv\" (
    echo ❌ 虚拟环境不存在，请先运行安装脚本
    echo.
    echo 请运行以下命令创建虚拟环境：
    echo python -m venv venv
    echo venv\Scripts\activate
    echo pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

REM 激活Python虚拟环境
echo 🔧 激活Python虚拟环境...
call venv\Scripts\activate

REM 检查依赖是否安装
python -c "import app.main" 2>nul
if errorlevel 1 (
    echo ❌ 依赖未正确安装，请检查安装过程
    echo.
    echo 请运行以下命令重新安装依赖：
    echo pip install --upgrade pip
    echo pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

REM 启动后端API服务
echo 📡 启动FastAPI服务器...
echo 🌐 服务地址: http://localhost:8080
echo 📖 API文档: http://localhost:8080/docs
echo.
echo 按 Ctrl+C 停止服务
echo ================================
echo.

python -m uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload

echo.
echo 服务已停止
pause
