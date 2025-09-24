# 🐧 Meetily Linux 迁移指南

## 📋 迁移兼容性

### ✅ **完全兼容的组件**
- **后端服务**: Python FastAPI + SQLite - 100% 兼容
- **AI模型**: Ollama + Whisper - 原生 Linux 支持
- **数据库**: SQLite - 跨平台
- **API接口**: 完全相同

### 🔧 **需要适配的组件**
- **桌面应用**: Tauri 会自动编译 Linux 版本
- **音频系统**: 需要安装 Linux 音频库
- **控制台功能**: Linux 版本功能有限（不影响核心功能）

## 🚀 Linux 部署方案

### 方案1: 直接迁移部署

#### 1. 系统环境准备

**Ubuntu/Debian 系统**：
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础依赖
sudo apt install -y \
    python3 python3-pip python3-venv \
    nodejs npm curl wget \
    build-essential pkg-config \
    libssl-dev libdbus-1-dev \
    libgtk-3-dev libwebkit2gtk-4.0-dev \
    libappindicator3-dev librsvg2-dev \
    pulseaudio pulseaudio-utils alsa-utils
```

**CentOS/RHEL 系统**：
```bash
# 安装 EPEL 仓库
sudo yum install -y epel-release

# 安装基础依赖
sudo yum install -y \
    python3 python3-pip \
    nodejs npm curl wget \
    gcc gcc-c++ make \
    openssl-devel dbus-devel \
    gtk3-devel webkit2gtk3-devel \
    libappindicator-gtk3-devel librsvg2-devel \
    pulseaudio pulseaudio-utils alsa-utils
```

#### 2. 安装开发工具

```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# 安装 pnpm
npm install -g pnpm

# 安装 Ollama (Linux 版本)
curl -fsSL https://ollama.ai/install.sh | sh

# 启动 Ollama 服务
ollama serve &
```

#### 3. 迁移项目文件

```bash
# 从 macOS 复制项目（方法1: scp）
scp -r meetily-offline-package/ user@linux-server:/home/user/meetily/

# 或者使用 rsync（更高效）
rsync -avz --progress meetily-offline-package/ user@linux-server:/home/user/meetily/

# 或者重新克隆项目
git clone https://github.com/alantany/meeting-minutes.git
cd meeting-minutes
```

#### 4. 安装依赖和启动

```bash
# 进入项目目录
cd meetily-offline-package

# 后端依赖安装
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..

# 前端依赖安装
cd frontend
pnpm install
cd ..

# 导入 AI 模型（如果从 macOS 导出了）
ollama pull deepseek-r1:14b

# 启动服务（使用现有脚本，完全兼容）
./start-backend.sh    # 终端1
./start-frontend.sh   # 终端2
```

### 方案2: Docker 容器化部署（推荐）

#### 1. 安装 Docker

**Ubuntu/Debian**：
```bash
# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo apt install -y docker-compose

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到 docker 组
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Docker 部署

```bash
# 进入项目目录
cd meetily-offline-package/backend

# 使用 Docker 脚本启动
./run-docker.sh

# 或者手动启动
docker-compose up -d
```

## 🔧 Linux 特定配置

### 音频权限设置

```bash
# 确保用户在音频组中
sudo usermod -aG audio $USER

# 重启音频服务
pulseaudio -k
pulseaudio --start

# 测试音频设备
arecord -l  # 列出录音设备
aplay -l    # 列出播放设备
```

### 防火墙配置

```bash
# Ubuntu (ufw)
sudo ufw allow 8080/tcp  # 后端 API
sudo ufw allow 3118/tcp  # 前端服务
sudo ufw allow 11434/tcp # Ollama

# CentOS (firewalld)
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=3118/tcp
sudo firewall-cmd --permanent --add-port=11434/tcp
sudo firewall-cmd --reload
```

### 系统服务配置（可选）

创建 systemd 服务文件：

```bash
# 后端服务
sudo tee /etc/systemd/system/meetily-backend.service > /dev/null <<EOF
[Unit]
Description=Meetily Backend Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER/meetily/backend
ExecStart=/home/$USER/meetily/backend/venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8080
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable meetily-backend
sudo systemctl start meetily-backend
```

## 🔍 Linux 特定差异

### 1. 控制台功能
```rust
// Linux 版本控制台功能有限，但不影响核心功能
#[cfg(not(any(target_os = "windows", target_os = "macos")))]
{
    Ok("Console control is only available on Windows and macOS".to_string())
}
```

### 2. 桌面应用
- **有桌面环境**: Tauri 应用正常运行
- **无桌面环境**: 使用 Web 版本 (http://localhost:3118)

### 3. 音频录制
- 需要正确配置 PulseAudio 或 ALSA
- 确保麦克风权限正确设置

## 📊 性能优化建议

### 1. 系统优化
```bash
# 增加文件描述符限制
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# 优化网络参数
echo "net.core.somaxconn = 1024" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 2. 内存管理
```bash
# 对于大模型，建议至少 16GB RAM
# 可以设置 swap 以防内存不足
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 🛠️ 故障排除

### 常见 Linux 问题

#### 1. 权限问题
```bash
# 确保文件权限正确
chmod +x start-backend.sh start-frontend.sh
sudo chown -R $USER:$USER /home/$USER/meetily/
```

#### 2. 依赖问题
```bash
# 如果缺少系统库
sudo apt install -y pkg-config libssl-dev

# 如果 Python 模块问题
pip install --upgrade pip setuptools wheel
```

#### 3. 音频问题
```bash
# 检查音频设备
pulseaudio --check -v

# 重启音频系统
sudo systemctl restart pulseaudio
```

#### 4. 端口占用
```bash
# 检查端口占用
sudo netstat -tlnp | grep :8080

# 终止占用进程
sudo kill -9 <PID>
```

## ✅ 验证部署

### 检查服务状态
```bash
# 检查后端
curl http://localhost:8080/get-meetings

# 检查 Ollama
ollama list

# 检查前端
curl http://localhost:3118
```

### 功能测试
1. **API 测试**: 访问 http://localhost:8080/docs
2. **前端测试**: 访问 http://localhost:3118 或桌面应用
3. **AI 测试**: 在应用中测试录音和转录功能

---

## 🎯 总结

**迁移难度**: ⭐⭐☆☆☆ (简单)

**兼容性**: ✅ 95% 兼容，核心功能完全相同

**推荐方案**: Docker 部署 > 直接迁移

**迁移时间**: 30分钟 - 2小时（取决于网络和系统配置）

Linux 迁移非常简单，项目的跨平台设计让整个过程几乎无缝！🎉
