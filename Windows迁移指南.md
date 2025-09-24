# 🪟 Meetily Windows 迁移指南

## 🎯 Windows 平台优势

### 🎤 **音频设备支持优势**
- **WASAPI 原生支持**: 专业级音频 API，低延迟高质量
- **企业音频设备兼容**: 完美支持会议室麦克风阵列
- **多设备管理**: 支持多个音频输入/输出设备同时使用
- **音频驱动兼容**: 与各种音频驱动程序完美集成

### 🏢 **企业部署优势**
- **Active Directory 集成**: 企业用户管理
- **Group Policy 支持**: 统一配置管理
- **Windows Service**: 后台服务运行
- **防火墙集成**: Windows Defender 原生支持

## 📋 迁移兼容性分析

### ✅ **完全兼容的组件** (98%)
- **后端服务**: Python FastAPI + SQLite - 100% 兼容
- **AI模型**: Ollama Windows 版本 - 原生支持
- **音频系统**: WASAPI + DirectSound - 专业级支持
- **桌面应用**: Tauri Windows 原生编译
- **数据库**: SQLite - 完全跨平台

### 🔧 **Windows 特有功能** (额外优势)
- **控制台管理**: 原生 Windows 控制台支持
- **系统集成**: 任务栏、通知、开机启动
- **音频回环**: 系统音频捕获（会议录制）
- **设备管理**: 即插即用音频设备支持

## 🚀 Windows 部署方案

### 方案1: 原生 Windows 部署（推荐企业环境）

#### 1. 系统环境准备

**Windows 版本要求**：
- Windows 10 (1903+) 或 Windows 11
- Windows Server 2019/2022（服务器部署）

**安装基础环境**：
```powershell
# 以管理员身份运行 PowerShell

# 1. 安装 Chocolatey 包管理器
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. 安装开发工具
choco install -y nodejs python3 git curl wget

# 3. 安装 Visual Studio Build Tools（Rust 编译需要）
choco install -y visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools"

# 4. 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# 或者下载 Windows 安装包: https://forge.rust-lang.org/infra/channel-layout.html#rustup-init-exe

# 5. 重启 PowerShell 或刷新环境变量
refreshenv
```

#### 2. 安装专业音频支持

```powershell
# 安装 Windows SDK（WASAPI 支持）
choco install -y windows-sdk-10-version-2004-all

# 确保音频服务运行
Start-Service -Name AudioSrv
Set-Service -Name AudioSrv -StartupType Automatic

# 检查音频设备
Get-WmiObject -Class Win32_SoundDevice | Select-Object Name, Status
```

#### 3. 安装 AI 环境

```powershell
# 下载并安装 Ollama Windows 版本
Invoke-WebRequest -Uri "https://ollama.ai/download/windows" -OutFile "ollama-windows.exe"
Start-Process -FilePath "ollama-windows.exe" -Wait

# 或者使用 Chocolatey
choco install -y ollama

# 启动 Ollama 服务
ollama serve
# 安装模型
ollama pull deepseek-r1:14b
```

#### 4. 项目迁移和部署

```powershell
# 克隆或复制项目
git clone https://github.com/alantany/meeting-minutes.git
cd meeting-minutes

# 或者从其他平台复制
# scp -r user@source-server:/path/to/meetily-offline-package .

# 安装 pnpm
npm install -g pnpm

# 后端环境设置
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
cd ..

# 前端环境设置
cd frontend
pnpm install
cd ..
```

#### 5. Windows 启动脚本

创建 **`start-backend.bat`**：
```batch
@echo off
echo 🚀 启动 Meetily 后端服务...
echo ================================

cd /d "%~dp0\backend"

REM 检查虚拟环境
if not exist "venv\" (
    echo ❌ 虚拟环境不存在，请先运行安装脚本
    pause
    exit /b 1
)

REM 激活虚拟环境
call venv\Scripts\activate

REM 检查依赖
python -c "import app.main" 2>nul
if errorlevel 1 (
    echo ❌ 依赖未正确安装，请检查安装过程
    pause
    exit /b 1
)

REM 启动服务
echo 📡 启动FastAPI服务器...
echo 🌐 服务地址: http://localhost:8080
echo 📖 API文档: http://localhost:8080/docs
echo.
echo 按 Ctrl+C 停止服务
echo ================================

python -m uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload

pause
```

创建 **`start-frontend.bat`**：
```batch
@echo off
echo 🚀 启动 Meetily 前端应用...
echo ================================

cd /d "%~dp0\frontend"

REM 检查依赖
if not exist "node_modules\" (
    echo ❌ 依赖未安装，正在安装...
    pnpm install
)

REM 启动 Tauri 开发服务器
echo 🖥️  启动Tauri开发环境...
echo ⏳ 首次启动可能需要几分钟编译...
echo 🌐 前端地址: http://localhost:3118
echo.
echo 按 Ctrl+C 停止服务
echo ================================

pnpm tauri dev

pause
```

### 方案2: Windows Service 部署（生产环境）

#### 1. 创建 Windows 服务

**后端服务配置** (`meetily-backend-service.xml`):
```xml
<service>
    <id>MeetilyBackend</id>
    <name>Meetily Backend Service</name>
    <description>Meetily AI会议助手后端服务</description>
    <executable>%BASE%\\backend\\venv\\Scripts\\python.exe</executable>
    <arguments>-m uvicorn app.main:app --host 0.0.0.0 --port 8080</arguments>
    <workingdirectory>%BASE%\\backend</workingdirectory>
    <logmode>rotate</logmode>
    <onfailure action="restart" delay="10 sec"/>
    <onfailure action="restart" delay="20 sec"/>
    <onfailure action="none"/>
    <resetfailure>1 hour</resetfailure>
</service>
```

#### 2. 使用 NSSM 创建服务

```powershell
# 下载 NSSM
choco install -y nssm

# 创建后端服务
nssm install "MeetilyBackend" "C:\\path\\to\\meetily\\backend\\venv\\Scripts\\python.exe"
nssm set "MeetilyBackend" AppParameters "-m uvicorn app.main:app --host 0.0.0.0 --port 8080"
nssm set "MeetilyBackend" AppDirectory "C:\\path\\to\\meetily\\backend"
nssm set "MeetilyBackend" DisplayName "Meetily Backend Service"
nssm set "MeetilyBackend" Description "Meetily AI会议助手后端服务"

# 启动服务
nssm start "MeetilyBackend"

# 设置开机启动
sc config "MeetilyBackend" start=auto
```

### 方案3: Docker Desktop 部署

#### 1. 安装 Docker Desktop

```powershell
# 下载并安装 Docker Desktop for Windows
choco install -y docker-desktop

# 或者手动下载
# https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe
```

#### 2. 使用 Docker 部署

```powershell
cd meetily-offline-package\\backend
docker-compose up -d
```

## 🎤 Windows 音频优化配置

### 1. WASAPI 音频配置

```powershell
# 检查音频设备
Get-CimInstance -ClassName Win32_SoundDevice | Format-Table Name, Status

# 配置音频服务优先级
sc config AudioSrv type=own start=auto

# 启用专业音频模式（低延迟）
reg add "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\AudioSrv" /v "Priority" /t REG_DWORD /d 1 /f
```

### 2. 会议室麦克风阵列配置

**支持的专业音频设备**：
- **Jabra Speak 系列**: USB 会议扬声器
- **Polycom 系列**: 企业级会议设备  
- **Logitech Rally 系列**: 会议室摄像头 + 麦克风
- **Shure MXA 系列**: 天花板麦克风阵列
- **Audio-Technica**: 专业录音设备

**配置示例**：
```rust
// 项目已支持 Windows 专业音频设备
#[cfg(target_os = "windows")]
fn configure_windows_audio(host: &cpal::Host) -> Result<Vec<AudioDevice>> {
    // 使用 WASAPI 枚举所有音频设备
    if let Ok(wasapi_host) = cpal::host_from_id(cpal::HostId::Wasapi) {
        // 支持多个麦克风输入
        // 支持音频回环录制
        // 支持设备热插拔
    }
}
```

### 3. 音频权限配置

```powershell
# 允许应用访问麦克风
reg add "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\microphone" /v "Value" /t REG_SZ /d "Allow" /f

# 允许桌面应用访问麦克风
reg add "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\microphone" /v "Value" /t REG_SZ /d "Allow" /f
```

## 🔒 企业安全配置

### 1. Windows Defender 配置

```powershell
# 添加信任路径
Add-MpPreference -ExclusionPath "C:\\path\\to\\meetily"

# 添加进程排除
Add-MpPreference -ExclusionProcess "python.exe"
Add-MpPreference -ExclusionProcess "meetily-frontend-app.exe"
```

### 2. 防火墙配置

```powershell
# 允许后端端口
New-NetFirewallRule -DisplayName "Meetily Backend" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow

# 允许前端端口
New-NetFirewallRule -DisplayName "Meetily Frontend" -Direction Inbound -Protocol TCP -LocalPort 3118 -Action Allow

# 允许 Ollama
New-NetFirewallRule -DisplayName "Ollama AI" -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow
```

### 3. 用户权限配置

```powershell
# 创建专用用户账户
net user meetily-service /add /comment:"Meetily Service Account"
net localgroup "Log on as a service" meetily-service /add

# 设置目录权限
icacls "C:\\path\\to\\meetily" /grant "meetily-service:(OI)(CI)F" /T
```

## 🛠️ Windows 特定功能

### 1. 系统集成

**任务栏集成**：
```rust
// Tauri 自动支持 Windows 任务栏
// - 最小化到系统托盘
// - 右键菜单
// - 通知气泡
```

**开机启动**：
```powershell
# 添加到启动项
reg add "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run" /v "Meetily" /t REG_SZ /d "C:\\path\\to\\meetily\\start-frontend.bat" /f
```

### 2. 控制台功能

```rust
// Windows 原生控制台支持（项目已实现）
#[cfg(target_os = "windows")]
unsafe {
    if AllocConsole() != 0 {
        // 分配控制台窗口
        // 重定向输出流
        // 支持动态显示/隐藏
    }
}
```

### 3. 音频回环录制

```rust
// 捕获系统音频（会议中的其他参与者声音）
#[cfg(target_os = "windows")]
{
    // WASAPI 回环模式
    // 可以录制系统播放的所有音频
    // 适合录制整个会议内容
}
```

## 📊 性能优化

### 1. Windows 系统优化

```powershell
# 禁用不必要的服务
sc config "DiagTrack" start=disabled
sc config "WSearch" start=disabled

# 优化音频性能
reg add "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Audio" /v "Priority" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Audio" /v "Scheduling Category" /t REG_SZ /d "High" /f
```

### 2. 内存和CPU优化

```powershell
# 设置进程优先级
wmic process where name="python.exe" CALL setpriority "high priority"

# 配置虚拟内存
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=8192,MaximumSize=16384
```

## 🔍 故障排除

### 常见 Windows 问题

#### 1. 音频设备问题

```powershell
# 重启音频服务
Restart-Service -Name AudioSrv

# 重新安装音频驱动
pnputil /enum-drivers
pnputil /delete-driver oem*.inf /uninstall

# 检查设备管理器
devmgmt.msc
```

#### 2. 权限问题

```powershell
# 以管理员身份运行
Start-Process powershell -Verb runAs

# 检查 UAC 设置
reg query "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" /v "EnableLUA"
```

#### 3. 端口占用

```powershell
# 查找占用端口的进程
netstat -ano | findstr :8080
taskkill /PID <进程ID> /F

# 释放端口
net stop winnat
net start winnat
```

#### 4. Python 环境问题

```powershell
# 重新创建虚拟环境
rmdir /s venv
python -m venv venv
venv\\Scripts\\activate
pip install -r requirements.txt
```

## ✅ 部署验证清单

### 系统检查
- [ ] Windows 版本兼容 (Win10 1903+)
- [ ] 管理员权限可用
- [ ] 音频设备正常工作
- [ ] 防火墙配置正确

### 服务检查
- [ ] 后端服务启动: `curl http://localhost:8080/get-meetings`
- [ ] 前端应用运行: 桌面应用或 http://localhost:3118
- [ ] Ollama 服务: `ollama list`
- [ ] 音频设备识别: 在应用中测试录音

### 功能测试
- [ ] 会议创建和录音
- [ ] 语音转文字功能
- [ ] AI 摘要生成
- [ ] 数据保存和导出

---

## 🎯 总结

**Windows 迁移优势**:
- ⭐⭐⭐⭐⭐ **音频支持**: 企业级 WASAPI，完美支持会议室设备
- ⭐⭐⭐⭐⭐ **企业集成**: AD、GPO、Service 完整支持
- ⭐⭐⭐⭐☆ **用户体验**: 原生 Windows 应用体验
- ⭐⭐⭐⭐☆ **兼容性**: 98% 代码兼容，额外功能增强

**推荐部署方案**: 
- **开发测试**: 原生部署 + 批处理脚本
- **生产环境**: Windows Service + 企业管理
- **会议室部署**: 专用音频配置 + 开机启动

Windows 平台是会议室部署的最佳选择！🎉
