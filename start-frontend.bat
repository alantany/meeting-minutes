@echo off
chcp 65001 >nul
title Meetily 前端应用

echo 🚀 启动 Meetily 前端应用...
echo ================================

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%frontend"

REM 检查node_modules是否存在
if not exist "node_modules\" (
    echo ❌ 依赖未安装，正在安装...
    echo.
    pnpm install
    if errorlevel 1 (
        echo ❌ 依赖安装失败，请检查 pnpm 是否安装
        echo.
        echo 请运行以下命令安装 pnpm：
        echo npm install -g pnpm
        echo.
        pause
        exit /b 1
    )
)

REM 设置Rust环境
echo 🔧 设置Rust环境...
call refreshenv 2>nul

REM 检查Rust是否可用
cargo --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Rust未安装或未在PATH中，请检查安装
    echo.
    echo 请安装Rust工具链：
    echo 1. 访问 https://rustup.rs/
    echo 2. 下载并运行 rustup-init.exe
    echo 3. 重启命令提示符
    echo.
    pause
    exit /b 1
)

REM 启动Tauri开发服务器
echo 🖥️  启动Tauri开发环境...
echo ⏳ 首次启动可能需要几分钟编译...
echo 🌐 前端地址: http://localhost:3118
echo.
echo 按 Ctrl+C 停止服务
echo ================================
echo.

pnpm tauri dev

echo.
echo 应用已停止
pause
