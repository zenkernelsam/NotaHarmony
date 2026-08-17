# HarmonyOS 模拟器操作指南（启动 / 恢复 / 部署）

> 2026-08-17 实测验证。适用：NotaHarmony 项目的 [Empty]（MatePad Pro 11）模拟器。
> 核心教训：**模拟器闪退后 Device Manager 会隐藏设备，绕过它用命令行直接启动。**

---

## 1. 标准启动流程（闪退后恢复）

### 1.1 检查设备状态

```powershell
& "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" list targets
# 127.0.0.1:12755 = 在线；[Empty] = 已掉线（设备被 Device Manager 隐藏）
```

### 1.2 杀掉僵尸进程（关键！根因在此）

闪退后常残留僵尸 Emulator 进程，DevEco 的 Device Manager 查询其状态失败
（`get hvd running status error: null`）→ 把 Tablet 从列表隐藏（只剩穿戴设备）：

```powershell
Get-Process | Where-Object { $_.ProcessName -match "Emulator|qemu" } | Select-Object Id, ProcessName
Get-Process -Name Emulator -ErrorAction SilentlyContinue | Stop-Process -Force
```

### 1.3 命令行启动（绕过 Device Manager，必须后台运行）

```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\emulator\Emulator.exe" `
  -hvd "MatePad Pro 11" `
  -path "C:/Users/Cisco He/AppData/Local/Huawei/Emulator/deployed" `
  -imageRoot "C:/Users/Cisco He/AppData/Local/Huawei/Sdk" `
  -hdcport 12755
```

⚠️ 关键参数：
- `-path` 必须指向 **deployed 根目录**（不是实例目录，否则报 "device not found"）
- `-hdcport` 必须在 **10000-16555** 范围（12755；参数未生效时可能用默认 5555，检测时两个端口都试）
- 看到 `Windows Hypervisor Platform accelerator is operational` 表示启动中

### 1.4 等待冷启动（1-2 分钟）再验证

```powershell
Start-Sleep -Seconds 90
& "...\hdc.exe" list targets   # 应显示 127.0.0.1:12755
```

### 1.5 可选：让 Device Manager 列表恢复

重启一次 DevEco Studio（模拟器已在命令行跑起来，DevEco 重启后会检测到运行中实例并显示）。

---

## 2. 部署应用

```powershell
$hdc = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
$hap = "C:\HarmonyProject\NotaHarmony\note\build\default\outputs\default\note-default-unsigned.hap"

# 安装（-r 覆盖重装）
& $hdc -t 127.0.0.1:12755 install -r $hap

# 启动
& $hdc -t 127.0.0.1:12755 shell aa start -a NoteAbility -b com.example.notaharmony

# 验证进程存活（返回 PID 即正常）
& $hdc -t 127.0.0.1:12755 shell "pidof com.example.notaharmony"
```

---

## 3. 已踩坑记录

### 3.1 ABI 不匹配（2026-08-17）

**现象**：`install parse native so failed. The Abi type supported by the device does not match the Abi type configured in the C++ project.`

**根因**：项目新增 C++ native 模块（nota_recording 录音 + nota_math/MicroTeX LaTeX），默认只构建 `arm64-v8a`；Windows 上的 HarmonyOS 模拟器是 **x86_64**（`hdc shell uname -m` 验证）。

**修复**：`note/build-profile.json5` 的 `externalNativeOptions` 添加：

```json5
"abiFilters": ["arm64-v8a", "x86_64"]
```

**影响**：构建时间增加（native 双 ABI 编译），HAP 体积增大。真机仍走 arm64-v8a，无影响。

### 3.2 模拟器依赖 DevEco Studio 图形界面

- 命令行启动模拟器前，DevEco Studio 需已运行（提供 Emulator 服务）；但 `deveco-mcp start_app` 的自动启动常失败，**手动命令行启动最可靠**。
- 未签名 HAP 通过 hdc install 可直接装进模拟器（真机需要签名）。

---

## 4. 相关路径速查

| 项 | 路径 |
|----|------|
| hdc | `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe` |
| Emulator.exe | `C:\Program Files\Huawei\DevEco Studio\tools\emulator\Emulator.exe` |
| DevEco 启动器 | `C:\Program Files\Huawei\DevEco Studio\bin\devecostudio64.exe` |
| 模拟器部署目录 | `C:/Users/Cisco He/AppData/Local/Huawei/Emulator/deployed` |
| 模拟器镜像根 | `C:/Users/Cisco He/AppData/Local/Huawei/Sdk` |
| HAP 产物 | `note/build/default/outputs/default/note-default-unsigned.hap` |
| 应用包名 | `com.example.notaharmony` / Ability `NoteAbility` |
