@echo off
chcp 65001 >nul
title Meetily Windows 环境安装

echo 🔧 Meetily Windows 环境安装脚本
echo =======================================
echo.

REM 检查管理员权限
net session >nul 2>&1
if errorlevel 1 (
    echo ⚠️  需要管理员权限来安装某些组件
    echo 请以管理员身份重新运行此脚本
    echo.
    pause
    exit /b 1
)

echo ✅ 管理员权限确认
echo.

REM 检查并安装 Chocolatey
echo 📦 检查包管理器 Chocolatey...
choco --version >nul 2>&1
if errorlevel 1 (
    echo 正在安装 Chocolatey...
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if errorlevel 1 (
        echo ❌ Chocolatey 安装失败
        pause
        exit /b 1
    )
    echo ✅ Chocolatey 安装成功
) else (
    echo ✅ Chocolatey 已安装
)

echo.
echo 🔧 安装开发工具...

REM 安装基础工具
echo 正在安装 Node.js...
choco install -y nodejs
echo 正在安装 Python...
choco install -y python3
echo 正在安装 Git...
choco install -y git
echo 正在安装 Visual Studio Build Tools...
choco install -y visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools"

echo.
echo 🔧 安装 Rust 工具链...
curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
if errorlevel 1 (
    echo ❌ Rust 安装失败，请手动安装
    echo 请访问: https://rustup.rs/
    pause
    exit /b 1
)

echo.
echo 🤖 安装 Ollama AI 环境...
choco install -y ollama
if errorlevel 1 (
    echo ⚠️  Chocolatey 安装 Ollama 失败，尝试手动下载...
    powershell -Command "Invoke-WebRequest -Uri 'https://ollama.ai/download/windows' -OutFile 'ollama-windows.exe'"
    echo 请手动运行 ollama-windows.exe 完成安装
    pause
)

echo.
echo 🔧 配置环境...

REM 刷新环境变量
call refreshenv

REM 安装 pnpm
echo 安装 pnpm 包管理器...
npm install -g pnpm

echo.
echo 🎤 配置音频服务...
sc config AudioSrv start=auto
net start AudioSrv

echo.
echo 🔒 配置防火墙...
netsh advfirewall firewall add rule name="Meetily Backend" dir=in action=allow protocol=TCP localport=8080
netsh advfirewall firewall add rule name="Meetily Frontend" dir=in action=allow protocol=TCP localport=3118
netsh advfirewall firewall add rule name="Ollama AI" dir=in action=allow protocol=TCP localport=11434

echo.
echo 📁 创建项目目录...
if not exist "backend\venv\" (
    echo 创建 Python 虚拟环境...
    cd backend
    python -m venv venv
    call venv\Scripts\activate
    pip install --upgrade pip
    if exist "requirements.txt" (
        pip install -r requirements.txt
    ) else (
        echo ⚠️  requirements.txt 不存在，请确保项目文件完整
    )
    cd ..
)

if exist "frontend\" (
    echo 安装前端依赖...
    cd frontend
    pnpm install
    cd ..
)

echo.
echo 🤖 启动 Ollama 服务并安装模型...
start /b ollama serve
timeout /t 5 /nobreak >nul
ollama pull deepseek-r1:14b

echo.
echo ✅ 安装完成！
echo ================================
echo.
echo 📋 安装总结：
echo ✅ Node.js 和 Python 环境
echo ✅ Rust 工具链
echo ✅ Ollama AI 环境
echo ✅ 防火墙配置
echo ✅ 音频服务配置
echo ✅ 项目依赖安装
echo.
echo 🚀 现在可以启动应用：
echo 1. 运行 start-backend.bat 启动后端
echo 2. 运行 start-frontend.bat 启动前端
echo.
echo 📖 详细说明请查看 Windows迁移指南.md
echo.
pause
