# Notability 鸿蒙移植项目 — 研究现状与探索指南

> 本文档面向接手本项目的朋友：介绍已完成的逆向分析成果、环境搭建方法、Frida 探索工具与登录绕过进展。
> 核心知识库在 `REVERSE_ANALYSIS.md`（当前 1–39 节），本文档只负责快速上手与开工状态判断；技术冲突一律以知识库最新带证据结论为准。
>
> **登录绕过完整复盘**：请优先阅读 [`LOGIN_BYPASS_RETROSPECTIVE.md`](LOGIN_BYPASS_RETROSPECTIVE.md)，其中记录了从 v13 失败、加载圈定位到 v14 成功进入 `o77` 的完整推理链、环境坑点和复现步骤。

---

## 1. 项目目标

将 Notability（iPadOS 经典笔记应用，2025 年首次发布 Android 版 1.0.1）移植到**鸿蒙平板**，深度适配华为手写笔 API，体验标准对标「iPad Notability + Apple Pencil」。

**当前建议技术路线**：
- 渲染：ArkUI Canvas 2D（先验证正确性）→ ArkGraphics 2D `ShaderEffect`（API 20+）→ XComponent + OpenGL ES（仅当前两层基准不足时）
- 输入与预测：ArkUI `TouchEvent` 采集真实/历史点，华为 Pen Kit `PointPredictor` 单独生成预测点；预测点不写入最终持久化笔画
- 几何：Force smoothing + 最小二乘三次贝塞尔分段拟合，并保留逐点宽度因子与可变宽度填充轮廓
- 数据：自研 op 流（参考原版）+ WebDAV 备份（差异化优势，原版没有）
- 存储：`@ohos.data.relationalStore`

上述路线是可实现、可量测的起点，不代表目标设备上的性能和“一比一手感”已经验证。

---

## 2. 已完成的逆向分析（核心成果）

### 2.1 应用架构（39 节知识库摘要）

| 模块 | 结论 | 章节 |
|------|------|------|
| SO 库 | 25 个第三方/运行时库；`libglmath.so` 是应用专用 LaTeX JNI，来源/所有权尚未证实 | §2 |
| 渲染架构 | **无 OpenGL**！AndroidX Ink + 自研 Canvas/Skia 渲染器 | §4 |
| 铅笔质感 | PencilSplat 完整公式（LCG 随机+椭圆盘+压感⁵缓动） | §18 |
| 普通钢笔/荧光笔 | “统一固定宽度”不成立；Taper/逐点宽度进入 `w4a.b()` 可变宽度轮廓，宽度因子来源仍待补 | §23、§35 |
| 笔画平滑 | Force smoothing + 最小二乘三次贝塞尔分段拟合；动态容差变量语义仍待补 | §17 |
| 低延迟 | 双 SurfaceControl+双 RenderNode+渲染线程 | §19 |
| 橡皮擦 | PARTIAL（clipOutPath 挖洞）+ WHOLE（整条删除） | §5b |
| 形状工具 | 笔画完成触发识别（非实时） | §24 |
| 选区工具 | Drawn/Lasso 模型 + 22 项菜单操作 | §25 |
| 纸张模板 | 程序化绘制+BitmapShader 平铺（间距 8px） | §7 |
| 文本/图片/录音 | 统一 c9e 元素模型 + NoteAsset 哈希引用 + audioLinked 回放 | §30-33 |
| Feature Flag | qa4 检查链（覆盖→远程→等级）+ 67 项枚举 | §29 |
| 备份 | **无第三方备份协议**（只有 Notability Cloud + Firebase） | 探索记录 |
| UI 主干 | `MainActivity → ComposeView → s4g.d`；主栈 `o77 → f89`，笔记内部默认路由 `zz8` | §39 |

### 2.2 鸿蒙替代方案（§12 完整对照表摘录）

| 原版 | 鸿蒙替代 |
|------|---------|
| MotionEvent / AndroidX Ink StrokeInput | ArkUI `TouchEvent`/`TouchPoint` + 真实点/历史点分轨采集 |
| Android predicted event | Pen Kit `PointPredictor`；C API `HMS_HandWrite_GetPredictPoint` 仅在目标 SDK 确认可用时采用 |
| Canvas + Path + Paint | ArkUI Canvas 2D；复杂可变宽度/纹理路径按基准评估 ArkGraphics 2D 或 OpenGL ES |
| RuntimeShader(AGSL) | AGSL 不可原样迁移；先 Canvas 2D 遮罩合成，再评估 `ShaderEffect`（API 20+）与 GLSL |
| SurfaceControl + RenderNode | **没有已证实的直接等价物**；用已完成层/当前笔画层/脏矩形架构，在目标设备比较 RenderNode、Canvas 与 XComponent 路线 |
| Room DB | @ohos.data.relationalStore |
| WorkManager | @ohos.backgroundTaskManager |

### 2.3 UI 入口与一比一移植依据（§39）

现在可以由真实代码入口恢复 UI，而不是只按截图猜布局：

```text
MainActivity
→ ComposeView.setContent(...)
→ s4g.d(...)
→ 主导航 aq8/jk8
   ├── o77 LibraryRoute
   │   └── Home 或 Notes / Shared / Folder 内容分发
   └── f89 NoteRoute
       └── xs7 笔记内部导航
           └── zz8 NoteCanvasRoute
```

已闭环的资料库响应式断点为 `600/840/952/1400dp`；在当前 280dpi 横屏模拟器上还量到 332dp 侧栏、48dp 点击区、24dp 图标和 64dp FAB。它们可作为 ArkUI 首版结构与尺寸基线，但主题 token、全部弹层锚点、动画以及 Light/Dark 状态仍需动态量测。

---

## 3. 环境搭建（ADB + 模拟器）

### 3.1 ADB 连接 MuMu 模拟器

```powershell
# ADB 工具（SchoolBox 项目内）
C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\platform-tools_ADB\adb.exe

# 连接 MuMu 模拟器（默认端口 7555）
& "C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\platform-tools_ADB\adb.exe" connect 127.0.0.1:7555

# 验证
& "...adb.exe" devices

# 安装 XAPK（必须用 install-multiple，逐个推所有 split APK）
& "...adb.exe" -s 127.0.0.1:7555 install-multiple `
  "c:\Users\Cisco He\Desktop\Notability\Notability\com.gingerlabs.notability.apk" `
  "c:\Users\Cisco He\Desktop\Notability\Notability\config.arm64_v8a.apk" `
  "c:\Users\Cisco He\Desktop\Notability\Notability\config.en.apk" `
  "c:\Users\Cisco He\Desktop\Notability\Notability\config.xxhdpi.apk"

# 常用命令
& "...adb.exe" -s 127.0.0.1:7555 shell "am force-stop com.gingerlabs.notability"   # 杀进程
& "...adb.exe" -s 127.0.0.1:7555 shell "am start -n com.gingerlabs.notability/.app.MainActivity"  # 启动
& "...adb.exe" -s 127.0.0.1:7555 shell "screencap -p /sdcard/s.png"                 # 截图
& "...adb.exe" -s 127.0.0.1:7555 shell "uiautomator dump /sdcard/ui.xml"            # UI 层级
```

### 3.2 Frida 环境（MuMu 模拟器）

**重要**：MuMu 是 x86_64 内核，arm64 frida-server 会 ptrace 失败，**必须用 x86_64 版**！

```powershell
# 1. 推送 x86_64 frida-server（已下载到 SchoolBox/Tools/frida-server-x86_64）
& "...adb.exe" -s 127.0.0.1:7555 push "C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\frida-server-x86_64" /data/local/tmp/frida-server-x86_64

# 2. 启动（root + 后台）
& "...adb.exe" -s 127.0.0.1:7555 shell "su -c 'chmod 755 /data/local/tmp/frida-server-x86_64; nohup /data/local/tmp/frida-server-x86_64 > /dev/null 2>&1 &'"

# 3. 端口转发 + 测试
& "...adb.exe" -s 127.0.0.1:7555 forward tcp:27042 tcp:27042
frida-ps -H 127.0.0.1:27042

# 4. Python 客户端（frida 16.1.11，与 server 版本匹配）
pip install frida==16.1.11 frida-tools==12.3.0
```

---

## 4. Frida 探索工具（frida_scripts/ 文件夹）

| 脚本 | 用途 |
|------|------|
| `bypass_login_v14.py` | **当前可用登录绕过**（zn7 + hnf 用户流注入 + 防登出 + 导航诊断） |
| `bypass_login_v13.py` | 历史实验版本；只伪造 LoginState，会卡在加载圈 |
| `capture_state_flow.py` | 捕获所有 StateFlow 发射（分析状态机） |
| `dump_login_state.py` | LoginState(zn7) 类结构 |
| `dump_user_class.py` | User(vmf) 类结构 |
| `dump_id_classes.py` | ID(iof)/订阅(lnf) 类结构 |
| `dump_user_repo.py` | 用户仓库(pa7) 方法签名 |
| `dump_main_stack.py` | 主线程堆栈（诊断卡顿） |
| `trace_login_render.py` | 登录页渲染调用链（un7 调用栈） |
| `verify_content_router.py` | 内容/路由进入情况验证（历史诊断脚本） |
| `find_classloader.py` | 查找 ClassLoader（PairIP 保护壳） |

### 4.1 登录绕过原理（v14，已验证进入主页面）

```
主界面进入条件：
  1. r26.a 初始化标记 = TRUE
     → hook xi7.K，按 CompositionLocal key 匹配返回 TRUE
  2. LoginState 必须满足 user != null && initializedLogin == false
     → un7 才会调用 resetToLibraryOrSurvey()
  3. hnf.e（完整 vmf 用户流）必须立即产生非 null 用户
     → 否则 hp8 case 5 会永远等待 first(hnf.e)，表现为全屏加载圈
  4. hnf.f（tmf 用户身份 StateFlow）也必须为非 null
  5. 防登出：block cr4.a(String)，并把 aq8.s() resetToLogin 重定向到 aq8.r()
```

v13 的关键错误是把 `zn7.c initializedLogin` 强制为 `true`。`un7` 的真实判断是：

```java
if (zn7Var2.a != null && !zn7Var2.c) {
    function0.invoke();
}
```

v14 在 `hnf.$init(w55, nmf, cr4, ou6)` 返回后：

- 构造 replay=1、已发射 fake `vmf` 的 `c3d`，包装成 `kbb` 后替换 `hnf.e`
- 构造保存 fake `tmf` 的 `knd`，替换 `hnf.f`
- 保留选择性 `bp.U()` fallback，防止 ART 忽略 final 字段反射写入
- 记录 `jk8` 导航栈；实测启动路由从 `si7` 进入 `o77`（`LibraryRoute`）

**已突破并实测**：登录页 ✅、加载圈 ✅、资料库主页面 `o77` ✅、笔记编辑器 ✅

验证截图：

- `Screenshot/notability_v14_home.png`：资料库壳的 **Notes 选中态**（文件名保留，但不是真正 Home 内容）
- `Screenshot/notability_v14.png`：真实 New Note 编辑器

**绕过的意义**：当前已经进入资料库与笔记编辑器，并完整还原了关键启动状态机；这些结果对鸿蒙版的状态分层和启动流程设计有直接指导价值。详细复盘见 `LOGIN_BYPASS_RETROSPECTIVE.md`。

### 4.2 关键混淆类名对照表

| 混淆名 | 真实身份 |
|--------|---------|
| zn7 | LoginState(user, loginInProgress, initializedLogin, ...) |
| vmf | User(id, name, email, authToken, useType, isAiEnabled, isBusiness) |
| r26.a | 初始化标记 CompositionLocal（key=s42.Q） |
| knd | StateFlow 包装（emit/k 是值入口） |
| cr4 | 强制登出服务（a(String) 触发登出） |
| we0 | MeQuery 会话验证（403 → cr4 登出） |
| fo7 | LoginState reducer |
| go7 | LoginViewModel |
| un7 | LoginScreen Compose 入口 |
| yw2 | 多用途合成 Lambda（不是主界面路由器） |
| gc8 | MotionEventConverter |
| rk9 | OkHttpClient |
| qk9 | OkHttpClient.Builder |

---

## 5. 工作区结构

```
Notability/
├── COMMANDER.md          ← 作战计划（任务队列/进度）
├── REVERSE_ANALYSIS.md   ← 知识库（1–39 节，核心资产）
├── START_PROMPTS.md      ← AI Agent 批量分析启动模板
├── PROJECT_HANDOVER.md   ← 本交接入口与开工状态
├── ENVIRONMENT_SETUP.md  ← ADB/Python/Frida 复现环境
├── reports/              ← 独立执行报告，README 规定命名与汇总流程
├── dump_exports.py       ← ELF so 导出表解析工具
├── frida_scripts/        ← Frida 探索与登录绕过脚本
├── decompiled/           ← jadx 反编译输出（sources + resources）
├── arm64_extracted/      ← 25 个第三方/运行时库 + 1 个应用专用 LaTeX JNI
├── xxhdpi_extracted/     ← 高密度资源（无笔刷纹理）
├── Screenshot/           ← v14 运行时截图、历史排障图与 N1–N4 营销素材
├── Notability/           ← XAPK 原始分包
└── jadx-1.5.6/           ← jadx 工具
```

---

## 6. 当前开工闸门

| 闸门 | 状态 | 当前判断 |
|------|------|----------|
| Android 逆向与动态研究环境 | ✅ | Python/ADB/Frida 已实测，v14 可进入资料库与编辑器 |
| UI/导航/MVP 技术规格 | ✅ 可开工 | 根入口、双层路由、响应式断点、手写核心路线足以开始结构原型 |
| HarmonyOS/ArkUI 工程 | ❌ 未创建 | 当前工作区没有 `.ets`、`module.json5`、`build-profile.json5`、`oh-package.json5` 或 Hvigor 工程文件 |
| HarmonyOS 构建工具链 | ❌ 未发现 | 2026-08-02 检查时，常见安装目录/PATH 中未发现 DevEco Studio、HDC、OHPM、Hvigor、Node、CMake 或 Ninja；DevEco 自带工具不在 PATH 的情况需安装后重新确认 |
| SDK/API/目标设备矩阵 | ❌ 未锁定 | 当前 ADB 仅列出 Android 模拟器端点，没有目标 HarmonyOS 平板；必须明确 SDK/API level、目标 MatePad/系统版本与降级范围 |
| 目标设备性能基准 | ❌ 未开始 | 尚未在目标设备测输入字段、P50/P95、掉帧、刷新率、预测点和帧加速 |
| 一比一视觉与手感 | 🟡 | 结构和单设备尺寸已有基线；主题、动画、弹层以及最终笔感仍需工程+真机校准 |

因此，准确说法是：**逆向研究与 UI/MVP 规格已足够开工，但完整移植环境和目标设备验证尚未就绪。**

### 建议立即执行的顺序

1. 创建最小 HarmonyOS/ArkUI 工程骨架，提交可运行的 Library/Note 双层导航空页面。
2. 安装/定位 DevEco Studio 与配套工具链，并锁定 SDK/API level、目标 MatePad、HarmonyOS 版本和最低兼容矩阵。
3. 建立手写输入原型：真实点、历史点、预测点分轨记录 pressure/tilt/orientation 与时间戳。
4. 建立 Canvas 2D → ArkGraphics 2D → XComponent/OpenGL ES 的同轨迹渲染基准。
5. 按 §39 先复刻资料库/编辑器结构、断点与点击热区，再补主题 token、弹层和动画。
6. 接入纸张模板、可变宽度轮廓、PencilSplat，并以真机数据决定优化路线。
7. MVP 稳定后再实现 op 流持久化、WebDAV 与高级功能。

---

## 7. 给新接手者的建议

1. **先读** `REVERSE_ANALYSIS.md` 的导航索引（文档开头）——当前 1–39 节知识地图
2. **再读** `COMMANDER.md` 的进度——知道做到哪了
3. 实现任务先确认 HarmonyOS 工程根目录和平台矩阵；当前仓库还没有目标端工程
4. 用 `START_PROMPTS.md` 分配边界明确的任务；普通执行者写入 `reports/`，主文档由单一汇总者更新
5. SO 已完成功能分类，不要机械重跑；其中 `libglmath.so` 是应用专用 LaTeX JNI，所有权仍未证实
6. 遇到卡顿先看 `dump_main_stack.py` 输出——该脚本为 attach 模式，需要 Notability 已运行

---

*最后更新: 2026-08-02*
*维护: 项目团队*
