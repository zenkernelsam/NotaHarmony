# Notability 项目 — 环境配置清单（给朋友的完整指南）

> 目标：在一台新电脑上复现「ADB + Python + Frida」完整环境。
> 所有版本号均为**已验证可用**的组合，请勿随意升级。
> 范围：本文只覆盖 Android 逆向/动态研究环境，不代表 HarmonyOS 目标端的 DevEco、SDK、HDC、OHPM、Hvigor 或真机环境已经配置。

---

## 1. 需要下载的东西（4 样）

| # | 工具 | 版本 | 说明 |
|---|------|------|------|
| 1 | Python | **3.12.x**（64位） | 建议 3.10-3.12，太新/太旧都可能踩坑 |
| 2 | platform-tools (ADB) | 任意较新版 | 谷歌官方，或直接用项目里的 |
| 3 | frida (pip 包) | **16.1.11** | 电脑端的 Python 客户端 |
| 4 | frida-server | **16.1.11-android-x86_64** | 模拟器里跑的守护进程 |

**⚠️ 版本匹配铁律：frida（电脑）和 frida-server（模拟器）必须同版本！**
不匹配会报 `unable to communicate with frida-server` 或直接连接失败。

---

## 2. 安装步骤

### 2.1 安装 Python
- 官网 https://www.python.org/downloads/ 下载 3.12.x Windows 安装包
- **安装时勾选 "Add Python to PATH"**（否则命令行找不到 python）
- 验证：`python --version`

### 2.2 安装 frida 客户端（电脑端）
```powershell
# 关键：指定版本号，不要装最新版！
pip install frida==16.1.11 frida-tools==12.3.0

# 验证
python -c "import frida; print(frida.__version__)"   # 必须输出 16.1.11
frida-ps --version
```

本机项目实测时请直接使用下面这个 Python，避免误用 Codex bundled runtime 或项目内旧的 `.tools/frida_py`：

```powershell
& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\python.exe" `
  -c "import frida; print(frida.__version__)"
```

### 2.3 获取 ADB
- 方式 A：用项目现成的 `SchoolBox\Tools\platform-tools_ADB\adb.exe`
- 方式 B：谷歌官方下载 platform-tools：https://developer.android.com/tools/releases/platform-tools
- 验证：`adb version`

### 2.4 获取 frida-server（模拟器版）
- 下载地址（GitHub）：https://github.com/frida/frida/releases/download/16.1.11/frida-server-16.1.11-android-x86_64.xz
- **必须选 x86_64 版**（MuMu 模拟器内核是 x86_64，arm64 版会 ptrace 失败）
- .xz 是压缩包，用 7-Zip 解压成 `frida-server-16.1.11-android-x86_64` 文件
- 重命名为 `frida-server-x86_64`，与本项目现有本地文件名保持一致

---

## 3. 连接 MuMu 模拟器

### 3.1 启动 MuMu 并开 ADB
MuMu 设置 → 其他 → 打开「ADB 调试」开关（默认开）。

### 3.2 ADB 连接（端口 7555）
```powershell
# 注意：路径有空格，必须用 & 调用，路径加引号
$ADB = "C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\platform-tools_ADB\adb.exe"

# 连接
& $ADB connect 127.0.0.1:7555
# 输出：connected to 127.0.0.1:7555

# 查看设备
& $ADB devices
# 输出：127.0.0.1:7555  device

# 安装 Notability（XAPK 必须用 install-multiple 逐个推 split APK！）
& $ADB -s 127.0.0.1:7555 install-multiple `
  "c:\Users\Cisco He\Desktop\Notability\Notability\com.gingerlabs.notability.apk" `
  "c:\Users\Cisco He\Desktop\Notability\Notability\config.arm64_v8a.apk" `
  "c:\Users\Cisco He\Desktop\Notability\Notability\config.en.apk" `
  "c:\Users\Cisco He\Desktop\Notability\Notability\config.xxhdpi.apk"

# 常用命令
& $ADB -s 127.0.0.1:7555 shell "am force-stop com.gingerlabs.notability"        # 杀应用
& $ADB -s 127.0.0.1:7555 shell "am start -n com.gingerlabs.notability/.app.MainActivity"  # 启动应用
& $ADB -s 127.0.0.1:7555 shell "screencap -p /sdcard/s.png"                     # 截图
& $ADB -s 127.0.0.1:7555 shell "uiautomator dump /sdcard/ui.xml"                # UI 层级
& $ADB -s 127.0.0.1:7555 pull /sdcard/s.png "c:\Users\Cisco He\Desktop\s.png"   # 拉取文件
```

---

## 4. 启动 frida-server（模拟器内）

```powershell
# 1. 推送 server 到模拟器
& $ADB -s 127.0.0.1:7555 push "C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\frida-server-x86_64" /data/local/tmp/frida-server-x86_64

# 2. 加执行权限 + 后台启动（需要 root，MuMu 自带 su）
& $ADB -s 127.0.0.1:7555 shell "su -c 'chmod 755 /data/local/tmp/frida-server-x86_64; nohup /data/local/tmp/frida-server-x86_64 > /dev/null 2>&1 &'"

# 3. 端口转发（模拟器 27042 → 本机 27042）
& $ADB -s 127.0.0.1:7555 forward tcp:27042 tcp:27042

# 4. 验证连接（在本机 PowerShell 执行）
frida-ps -H 127.0.0.1:27042
# 成功：列出模拟器所有进程（含 Notability）
# 失败常见原因：
#   - frida-server 版本与 pip 的 frida 不一致
#   - 推的是 arm64 版 server（x86_64 模拟器上 ptrace 失败）
#   - server 没起来（PowerShell：& $ADB shell "su -c 'ps -A'" | Select-String -Pattern 'frida'）
```

---

## 5. 运行 Frida 脚本

脚本分为两种模式：

| 模式 | 脚本 | 使用前提 |
|------|------|----------|
| spawn 后注入 | `bypass_login_v14.py`、`bypass_login_v13.py`、`capture_state_flow.py`、`dump_*` 中除下列两项外的大多数脚本、`trace_login_render.py`、`verify_content_router.py` | 脚本会启动应用并 attach 到新进程 |
| attach 到现有进程 | `dump_main_stack.py`、`find_classloader.py` | 先手动启动 Notability，确认进程存在后再运行 |

```powershell
# 所有脚本在 Notability\frida_scripts\ 目录
cd "c:\Users\Cisco He\Desktop\Notability\frida_scripts"

# v14 是 spawn 模式：自动启动应用并注入
& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\python.exe" `
  -u bypass_login_v14.py
# 运行后脚本会：
#   1. spawn Notability
#   2. 注入 hook（r26.a + zn7 + hnf.e/f 用户流 + 防登出）
#   3. 保持运行（Ctrl+C 停止）

# 自动诊断 20 秒后退出（便于收集完整日志）
& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\python.exe" `
  -u bypass_login_v14.py --duration 20
```

`bypass_login_v13.py` 仅保留作历史对照：它会离开登录页，但因底层 `hnf.e/f` 仍为 null 而卡在加载圈。

---

## 6. 常见问题排查表

| 症状 | 原因 | 解决 |
|------|------|------|
| `frida-ps -H 127.0.0.1:27042` 连接失败 | server 没启动/版本不匹配 | 重推 server + 确认版本 16.1.11 |
| `unable to perform ptrace getregs` | 用了 arm64 版 server | 换 **x86_64** 版 |
| `ProcessNotFoundError` | 进程名不对 | Frida 显示名是 `Notability`（非包名），或先 `frida-ps -H` 查 |
| Python 找不到 frida | pip 装错 Python 环境 | `python -m pip install frida==16.1.11` |
| `adb: no devices/emulators found` | 没连接模拟器 | `adb connect 127.0.0.1:7555` |
| `adb install` 报错 | XAPK 不能直接 install | 用 `install-multiple` + 全部 split APK |
| PowerShell 执行报「意外标记」 | 路径含空格没加引号 | `& "完整路径含引号" -参数` |
| 脚本报 `class not found (defpackage.xxx)` | Frida 需要裸类名 | 用 `u8`/`zn7` 而非 `defpackage.u8` |

---

## 7. 关键文件位置速查

```
# 本机工具（已在用户机器上验证可用）
ADB 路径:      C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\platform-tools_ADB\adb.exe
frida-server:  C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\frida-server-x86_64 (108MB, x86_64)

# 项目文件
Frida 脚本:    c:\Users\Cisco He\Desktop\Notability\frida_scripts\
反编译源码:    c:\Users\Cisco He\Desktop\Notability\decompiled\sources\
知识库:        c:\Users\Cisco He\Desktop\Notability\REVERSE_ANALYSIS.md
交接文档:      c:\Users\Cisco He\Desktop\Notability\PROJECT_HANDOVER.md

# 模拟器连接信息
地址: 127.0.0.1:7555 (ADB) / 127.0.0.1:27042 (Frida)
应用包名: com.gingerlabs.notability
```

---

## 8. 版本核对表（照抄即可）

2026-08-02 本机已验证组合：Python **3.12.10**、Frida/`frida-ps` **16.1.11**、ADB **37.0.1**，且 `127.0.0.1:27042` 可以列出 Notability。

```powershell
# 全部装完后，逐条验证：
python --version                        # Python 3.12.x
python -c "import frida; print(frida.__version__)"   # 16.1.11
frida-ps --version                      # 16.1.11
adb version                             # 任意新版
frida-ps -H 127.0.0.1:27042             # 能列出进程 = 全通！
```

---

## 9. HarmonyOS 目标端环境状态

截至 2026-08-02，本机只验证了上面的 Android 研究链路。当前检查结果：

- 工作区没有 `.ets`、`module.json5`、`build-profile.json5`、`oh-package.json5` 或 Hvigor 工程文件。
- 常见安装目录/PATH 中未发现 DevEco Studio、HDC、OHPM、Hvigor、Node、CMake 或 Ninja。部分工具可能由 DevEco 内置且不加入 PATH，安装后应记录其真实位置与版本。
- `adb devices -l` 当前只列出 Android 模拟器端点，没有目标 HarmonyOS/MatePad 设备；目标端连接应以 HDC 和 DevEco 的设备列表重新验证。

开始 ArkUI 实现前必须补齐：DevEco Studio、目标 HarmonyOS SDK/API level、可构建运行的工程骨架、目标 MatePad/系统版本、HDC 部署链路与性能测试矩阵。

---

*配置人: 项目团队 | 2026-08-02*
