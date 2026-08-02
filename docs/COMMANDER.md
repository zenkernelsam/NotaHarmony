# 🎯 指挥官文档 — Notability 逆向分析作战计划

> 每次开工前打开这个文件，看当前阶段和下一步行动。
> 完成一项就勾掉，卡住了就记录到「阻塞」区。

---

## 当前阶段：审计收尾 + HarmonyOS 目标端 MVP 原型验证

**目标**：把会影响架构的逆向结论收口，创建可运行的 HarmonyOS/ArkUI 工程骨架，建立可量测的一比一 UI 基线，并用最小原型验证输入、可变宽度、铅笔纹理和低延迟能力。

**当前原则**：

- 逆向结论必须区分“代码存在、业务调用、官方能力、真机验证”。
- 先实现可测的最小闭环，再根据数据决定 Canvas 2D、ArkGraphics 2D 或 OpenGL ES 路线。
- Pen Kit、StylusFrameBoost 等属于华为 HarmonyOS SDK；没有 OpenHarmony 上游证据时，不写成 OpenHarmony 通用能力。
- `REVERSE_ANALYSIS.md` 的带证据结论是技术知识库；本文件顶部是当前状态。下方 Day 0-5 内容仅是历史记录。
- 历史记录与当前结论冲突时，以原始代码/官方文档和 `REVERSE_ANALYSIS.md` 最新审计结论为准。

---

## 分析任务队列（按优先级排序）

### 🔴 P0 — 手写核心（必须先搞懂）

| # | 任务 | 工具 | 看什么 | 状态 |
|---|------|------|--------|------|
| 1 | 笔画数据模型 | jadx | `data/note/ops/` 下的类，找 stroke 的字段定义（点、压感、工具、颜色） | ✅ s78+PencilSplat+WetMirrorRenderSpec |
| 2 | 笔刷纹理资源 | APK 解压 | 在 base APK 的 assets/ 或 res/ 里找 stamp/brush 相关图片 | ✅ ui_renderer__pencil_splat.png |
| 3 | 渲染调用链 | jadx | 业务层实时墨迹如何生成并上屏 | ✅ AndroidX Ink 渲染辅助 + Notability 自定义 workflow（第4节） |
| 4 | 输入事件处理 | jadx | 找 MotionEvent/预测事件 → AndroidX Ink StrokeInput 的转换链 | ✅ `cxe.i/ys0 → oc8/nc8 → uc8 → szf/nzf → cu5 → hda`（第5节） |
| 5 | 橡皮擦逻辑 | jadx | 搜索 eraser 相关类，确认是像素擦除还是笔画擦除 | ✅ 两种都有（PARTIAL/WHOLE） |

### 🟡 P1 — 笔记结构（搞懂数据才能设计存储）

| # | 任务 | 工具 | 看什么 | 状态 |
|---|------|------|--------|------|
| 6 | FlatBuffers schema | jadx/IDA | `core/flatbuffers/` + 搜索 `.fbs` 或 schema 定义 | 🟡 已确认 op 流模式，schema 细节待解析 |
| 7 | 页面管理 | jadx | 多页笔记怎么组织？页面尺寸/顺序/背景怎么存？ | 🟡 确认在 op 流中，待深挖 |
| 8 | 纸张模板渲染 | jadx | 搜索 grid/rule/dots 相关绘制代码 | ✅ 页面背景由 qae 程序化绘制；另有 15 张预览缩略图 |
| 9 | 笔记库结构 | jadx | `data/library/state/` — 文件夹、笔记元数据、排序 | 🟡 SyncedNoteMetadata 已还原 |
| 10 | 本地数据库 | jadx | Room Entity/DAO 定义，看表结构 | ✅ 全部表结构已还原（第8节） |

### 🟢 P2 — UI/交互（可以边做边看）

| # | 任务 | 工具 | 看什么 | 状态 |
|---|------|------|--------|------|
| 11 | 编辑器工具栏 | 截图 + jadx | 工具列表、切换逻辑、样式面板 | 🟡 根入口、主工具栏/右侧工具轨和主要 action 已定位；样式弹层与动画待量测（第39节） |
| 12 | 选区工具 | jadx | 套索选区 → 变换（移动/缩放/旋转）的实现 | ✅ Drawn/Lasso + 统一 transform（第25节） |
| 13 | 文本框 | jadx | 文本输入、排版、编辑的实现 | ✅ TextBlockInfo + StaticLayout + 统一变换（第30节） |
| 14 | 导航结构 | jadx + 运行日志 | Compose 导航图，页面间跳转逻辑 | 🟡 主导航 `o77→f89` 与笔记内部 `zz8` 双层结构已确认；其它次级路由待枚举（第39节） |
| 15 | 主题/暗色模式 | jadx + res | `data/theme/` 的实现 | ⬜ |

### 🔵 P3 — 高级功能（后期再看）

| # | 任务 | 工具 | 看什么 | 状态 |
|---|------|------|--------|------|
| 16 | 录音 + 时间锚点 | jadx | `feature/note/toolbox/audio/` | 🟡 服务与 audioLinked 字段已定位；时间戳→回放进度赋值链待补（第32节） |
| 17 | PDF 导入/标注 | jadx + PDF SDK 文档 | 应用如何调用 PDFNetC、页面如何进入笔记模型 | ⬜ |
| 18 | 手写识别流程 | jadx | `lj8.java` 的完整调用链 | 🟡 MyScript 入口和转换功能已定位，完整调用链待补 |
| 19 | 同步协议 | jadx | `data/note/ops/synced/` + GraphQL schema | 🟡 op 流/元数据已确认，顶层类型分发仍待解析 |
| 20 | 图片插入 | jadx | 图片嵌入笔记的方式 | 🟡 NoteAsset 哈希存储已确认，具体图片元素类待定位（第31节） |

---

## 每次分析的标准流程

```text
1. 打开本文件和 REVERSE_ANALYSIS.md，选择一个当前 🟡/⚠️/⬜ 项
2. 回到反编译代码、运行结果或官方文档核验
3. 普通执行者把发现写入独立 reports/*.md
4. 唯一汇总者交叉检查后更新 REVERSE_ANALYSIS.md
5. 汇总者同步本文件状态和「上次进度」
6. 真正无法推进的事项写入「阻塞/疑问」
```

---

## ❗ 给 AI Agent 的重要规则

> **每个 Agent 开工前必须先读这段。**

### 规则 1：先读后做
开工前先读这两个文件，获取完整上下文：
- `c:\Users\Cisco He\Desktop\Notability\COMMANDER.md` — 作战计划和任务状态
- `c:\Users\Cisco He\Desktop\Notability\REVERSE_ANALYSIS.md` — 已有知识库

### 规则 2：分级记录证据
- ✅：调用链/数据含义已闭环，并附文件+方法/行号、运行结果或官方链接。
- 🟡：主体已定位，但参数语义、全部分支或真机表现尚未闭环。
- ⚠️：仅有线索或推断，不能作为实现承诺。
- ❓：尚未定位。
- 记录时写清楚「发现了什么 + 原始证据 + 为什么重要 + 仍缺什么」。

### 规则 3：单一写入者
- 多个执行者可以并行读代码，但分别写 `reports/YYYY-MM-DD-主题-执行者.md`。
- 同一时间只能有一个汇总者修改 `COMMANDER.md` 和 `REVERSE_ANALYSIS.md`，防止覆盖。
- 汇总者完成交叉检查后再更新状态；不能因“任务有人做过”就自动标 ✅。

### 规则 4：不要重复工作
- 如果 REVERSE_ANALYSIS.md 里已有答案，先核验证据和状态，再决定是否需要复审
- 已完成功能分类的 SO 不要机械重跑；注意 `libglmath.so` 是应用专用 LaTeX JNI，来源/所有权尚未证实
- 看「分析状态总结」表，已完成的跳过
- Day 0 的资源枚举、SO 身份和基础模型任务已完成，禁止机械重跑

### 规则 5：聚焦产出
- 每个 Agent 的目标是产出**结构化的知识**，不是聊天
- 输出格式：表格 / 代码块 / 调用图 / 字段列表
- 普通执行者写独立报告；主文档只由汇总者写

### 规则 6：避免逆向分析常见误判
- “全局搜索无调用”不是“业务未使用”的充分证据；还要检查接口、反射、协程/Compose lambda、native 和 R8 合并分支。
- R8 合并类只能按具体构造器、方法或 `switch` 分支命名，不能把整个类统一解释成单一业务职责。
- 同名第三方类型不代表业务入口；必须从 Notability 的入口和调用者建立闭环。
- 代码存在不等于运行时走到；平台有 API 不等于性能指标已经达成。

### 规则 7：善用工具，主动开口
- 需要 MCP 工具（如 IDA Pro MCP）→ **直接告诉用户，请尽管开口**
- 需要安装新的 MCP 服务器 → **直接说，用户会配合**
- 需要联网搜索（查官方文档、API 参考、开源实现）→ **主动去搜**
- 需要 Skill（如 canvas 可视化、浏览器操作）→ **直接用**
- 原则：工具能解决的事不要硬靠脑子猜，能查到的不要靠记忆

---

## 本轮进展

- **日期**: 2026-08-02
- **完成**:
  - 核心审计纠错：真实输入链、普通平滑、可变宽度轮廓、RuntimeShader/HardwareBuffer 和 HarmonyOS API 边界已重新核验。
  - 朋友协作完成 v14：注入底层用户流 `hnf.e/f`、修正 `initializedLogin` 语义并记录真实导航栈。
  - **本地模拟器验证**：登录页 → 加载阶段 → 资料库 `o77` → 笔记编辑器均可进入。
  - 截图: `Screenshot/notability_v14_home.png` / `notability_v14.png` / `notability_v14_library.png`
  - 脚本: `frida_scripts/bypass_login_v14.py`（--duration 20 自动诊断）
  - 完整复盘: `LOGIN_BYPASS_RETROSPECTIVE.md`
  - 知识库新增 §38 启动状态机（四层状态：r26.a/zn7/hnf.e-f/aq8）
  - 知识库新增 §39 UI 移植地图：`MainActivity → ComposeView → s4g.d` 根入口、`o77/f89/zz8` 双层路由、资料库响应式断点和编辑器组件入口已闭环。
  - **动态 UI 复核**：`logcat` 观察到主栈 `o77, f89` 与笔记内部栈 `zz8`；280dpi 横屏下量到 332dp 侧栏、48dp 工具点击区、24dp 图标和 64dp FAB。
  - 截图命名纠正：`notability_v14_home.png` 实际是 Notes 选中态，不是 Home 内容；保留文件名但不再误用为 Home 页面证据。
  - **全量 Markdown 审计**：项目文档已按 §39 和最新手写结论统一；纠正交接文档中的 SO 身份、固定宽度钢笔、实时形状拟合、`PenEvent` 与 SurfaceControl 直接替代等旧说法。
  - **开工资料补齐**：同步环境脚本的 spawn/attach 模式，修正 `LibraryRoute`/截图标签，并新增 `reports/README.md` 使独立报告工作流可直接执行。
- **关键教训**:
  - `initializedLogin` 必须是 **false** 才触发 resetToLibraryOrSurvey（AI 早期搞反了）
  - 本次加载阶段的直接阻塞点是 `first(hnf.e)` 等不到首值；这不等于已排除所有服务器/会话上游原因。
  - 伪造用户必须四层自洽：UI 状态 + 用户流 + 身份流 + 导航
  - Frida 只负责让原有 UI 状态机继续运行；HarmonyOS 产品代码应移植 `o77/f89/zz8` 后的真实页面结构，不移植 fake user/reset hook。
- **下次从**: 创建 HarmonyOS/ArkUI 工程骨架、锁定目标平台矩阵，然后落地输入/渲染基准与 UI 结构页（见下方「当前行动」）

---

## 开工闸门

| 闸门 | 状态 | 说明 |
|------|------|------|
| Android 逆向环境 | ✅ | Python/ADB/Frida 已验证，v14 可进入资料库和编辑器 |
| UI/MVP 规格 | ✅ 可开工 | 根入口、双层路由、断点、尺寸基线和手写核心路线足够创建结构原型 |
| HarmonyOS/ArkUI 工程 | ❌ | 当前工作区没有 `.ets`、`module.json5`、`build-profile.json5`、`oh-package.json5` 或 Hvigor 文件 |
| HarmonyOS 构建工具链 | ❌ | 常见安装目录/PATH 中未发现 DevEco Studio、HDC、OHPM、Hvigor、Node、CMake 或 Ninja，安装后仍需记录实际路径与版本 |
| SDK/API/目标 MatePad | ❌ | 当前 ADB 只有 Android 模拟器端点，没有目标 HarmonyOS 平板；平台矩阵和 Pen Kit/ShaderEffect/帧加速范围不能定案 |
| 真机性能验证 | ❌ | 尚无目标设备输入字段、P50/P95、掉帧和刷新率基准 |
| 一比一视觉与手感 | 🟡 | 结构/单设备尺寸已有基线；主题、动画、弹层与最终笔感仍待工程和真机校准 |

结论：逆向研究与 UI/MVP 规格已经足够开工，但不能声称完整移植环境、性能和一比一体验已经定型。

---

## 当前行动

| 优先级 | 行动 | 完成标准 |
|--------|------|----------|
| P0 | 创建 HarmonyOS/ArkUI 工程骨架 | 工程可在选定 DevEco/SDK 上构建运行，包含 Library/Note 双层导航空页面和基础状态层 |
| P0 | 锁定目标平台矩阵 | 记录 DevEco、SDK/API level、目标 MatePad/系统版本；逐项确认 Pen Kit、ShaderEffect、帧加速与降级路径 |
| P0 | 建立输入原型 | 原始/历史/预测点分别采集，输出 pressure/tilt/orientation 缺失值和设备能力日志 |
| P0 | 建立渲染基准 | 对比 Canvas 2D、ArkGraphics 2D ShaderEffect；记录 P50/P95、掉帧、笔画长度和设备刷新率 |
| P1 | 建立 UI 一比一基线 | 在 600/840/952/1400dp 和 Light/Dark 下记录尺寸、字体、颜色、圆角、阴影、菜单锚点、duration/easing；区分代码常量、运行时量测和截图估计 |
| P1 | 恢复逐点宽度来源 | 找到 `fc0.e()` 的写入/生成链，区分工具默认样式、压感、Taper 和编辑后宽度 |
| P1 | 收口普通平滑 | 解释 `ms1.b()` 中动态容差公式的每个变量，并覆盖 Pen/Highlighter/Eraser 等分支 |
| P1 | 解析 op 顶层分发 | 得到页面增删、笔画插入/删除/变换等 op 类型和引用关系 |
| P1 | 收口 P2 元素缺口 | 找到图片元素/裁剪/z-order，并恢复录音时间戳→`audioLinkedProgress` 赋值链 |

MVP 第一阶段只承诺“可测”，不预先承诺 `<16ms`。预测点用于实时预览，最终持久化应以真实采样点为准。

---

## 📅 Day 5 计划 — 风险排查（三大坑）

> **历史记录**：以下 Day 0-5 是当时的任务说明，不再直接复制执行；旧结论已由本次复核修正。
> 当前结论以本文件顶部状态和 `REVERSE_ANALYSIS.md` 最新章节为准。

### 任务队列

| # | 任务 | 具体目标 | 状态 |
|---|------|---------|------|
| 1 | **钢笔可变宽度确认** | 钢笔沿路径是否有逐点宽度变化？Taper 如何渲染？ | 🟡 Taper→VARIABLE_WIDTH + `w4a.b()` 轮廓已确认；宽度因子来源待补（第35节） |
| 2 | **鸿蒙低延迟 API 调研** | 预测点、帧加速、渲染节点分别能提供什么？ | 🟡 华为 HarmonyOS SDK 能力边界已确认；不存在已证实的 SurfaceControl 直接等价物，延迟需真机量测（第36节） |
| 3 | **鸿蒙 Shader 兼容性** | 无 AGSL 源码兼容时有哪些原生/GL 路径？ | ✅ 能力边界已确认；Canvas2D→ShaderEffect(API20+)→OpenGL ES 分层验证（第37节） |

### Agent 指令

**Agent 1：钢笔可变宽度确认（代码分析）**
```
[通用开头：读 COMMANDER.md + REVERSE_ANALYSIS.md]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中确认钢笔是否有沿路径的压感宽度变化：

背景：
- 铅笔 = PencilSplat（每个点独立 scale，已确认）
- 钢笔 = pzf.g() 绘制 Path + strokeWidth
- 问题：strokeWidth 是固定的？还是沿路径变化的？

分析步骤：
1. 读 defpackage/pzf.java 的 g() 方法：
   - paint.setStrokeWidth() 的值从哪来？是常量还是变量？
   - 是 drawPath(整个路径) 还是分段绘制（每段不同宽度）？

2. 搜索 "SizeBehavior" / "sizeBehavior" / "pressureSize" 在 androidx/ink/ 和 defpackage 中：
   - AndroidX Ink 的 BrushTip 有 SizeBehavior（压感→大小）
   - Notability 有没有配置它？

3. 搜索 "tapered" / "variable_width" / "width_at_point" 在 defpackage 中：
   - 有没有沿路径宽度变化的证据？

4. 读 AndroidX Ink 的 BrushBehaviorNative.java：
   - 节点类型有哪些？（SIZE_PRESSURE? SIZE_TILT?）
   - Notability 创建了哪些 Behavior 节点？

5. 搜索 "StockBrushes" / "pressurePen" 在 defpackage 中：
   - AndroidX Ink 自带的 pressurePen 笔刷有没有被使用？

目标：给出明确结论——
  A) 钢笔是固定宽度（只有 Taper 收笔变细）→ 简单，strokePath 就行
  B) 钢笔有压感宽度变化 → 需要轮廓多边形算法，复杂度升级
输出：结论 + 证据链，写入 REVERSE_ANALYSIS.md 第 35 节。
```

**Agent 2：鸿蒙低延迟 API 调研（联网）**
```
[通用开头]

任务：联网调研鸿蒙的手写笔低延迟能力：

1. 搜索 "HarmonyOS HandWrite API" / "鸿蒙 手写笔 低延迟" / "hms_hand_write"：
   - HandWrite 模块提供什么能力？
   - 预测点 API (hms_hand_write_get_predict_point) 的具体参数和用法
   - 延迟指标（官方宣称多少 ms？）

2. 搜索 "HarmonyOS XComponent 低延迟渲染" / "鸿蒙 RenderNode" / "鸿蒙 SurfaceControl"：
   - 鸿蒙有没有类似 Android SurfaceControl 的硬件层合成 API？
   - XComponent 的渲染延迟特性
   - 有没有双缓冲/前端缓冲的官方支持？

3. 搜索 "HarmonyOS ArkGraphics 2D 硬件加速" / "鸿蒙 drawVertices"：
   - ArkGraphics 2D 的性能特性
   - 是否支持离屏渲染 + 层合成

4. 搜索 "华为 MatePad 手写笔 延迟测试" / "M-Pencil 延迟"：
   - 实际用户反馈的延迟体验
   - 和 Apple Pencil 的对比

目标：给出结论——
  - 鸿蒙能否实现 <16ms 的笔迹延迟？
  - 具体用哪些 API？
  - 和 Android SurfaceControl 的等价物是什么？
输出：API 能力表 + 延迟方案建议，写入 REVERSE_ANALYSIS.md 第 36 节。
```

**Agent 3：鸿蒙 Shader 兼容性调研（联网）**
```
[通用开头]

任务：联网调研鸿蒙的 Shader/自定义渲染能力：

1. 搜索 "HarmonyOS AGSL" / "鸿蒙 RuntimeShader" / "ArkUI shader"：
   - 鸿蒙是否支持类似 Android AGSL 的 RuntimeShader？
   - 如果支持，API 是什么样的？
   - 如果不支持，有什么替代？

2. 搜索 "HarmonyOS XComponent OpenGL ES" / "鸿蒙 NDK OpenGL"：
   - XComponent + OpenGL ES 的支持情况
   - 能否在 XComponent 上自定义 shader？

3. 搜索 "HarmonyOS drawVertices" / "鸿蒙 网格渲染" / "ArkGraphics mesh"：
   - 有没有类似 Canvas.drawVertices 的 API？
   - 或者通过 OpenGL ES 自己实现？

4. 搜索 "HarmonyOS Skia" / "鸿蒙 2D 渲染引擎"：
   - 底层是否用 Skia？
   - 能否通过 NDK 直接调用 Skia API？

目标：给出结论——
  - 铅笔纹理渲染（RuntimeShader + drawVertices）在鸿蒙上怎么实现？
  - 方案 A：鸿蒙原生支持 AGSL → 直接迁移
  - 方案 B：XComponent + OpenGL ES 自写 shader
  - 方案 C：Canvas 2D 简化版（性能/效果降级）
输出：方案对比表 + 推荐路线，写入 REVERSE_ANALYSIS.md 第 37 节。
```

---

## 📅 Day 4 计划 — P2 功能全分析 + 共享抽象层

> 目标：把剩余功能全部挖出来，重点找「它们共用了什么」——元素模型、op 流、transform、渲染层。
> 原则：每个功能都记录「它用了哪些共享组件」，最后汇总成抽象层地图。

### 任务队列

| # | 任务 | 具体目标 | 状态 |
|---|------|---------|------|
| 1 | **文本框工具** | 文本创建/编辑/排版/渲染，与笔画元素的共存方式 | ✅ TextBlockInfo+StaticLayout+统一ID（第30节） |
| 2 | **图片插入与标注** | 图片嵌入笔记的方式、标注层、与笔画的层级关系 | 🟡 NoteAsset 哈希+Worker 已确认；具体元素类、裁剪与层级仍待确认（第31节） |
| 3 | **录音 + 时间锚点** | 录音与笔记的关联机制、回放时笔迹动画 | 🟡 服务/字段已定位，时间映射赋值链待补（第32节） |
| 4 | **共享抽象层地图** | 所有元素类型的统一模型、op 流顶层分发、渲染层接口 | 🟡 c9e 基类+三渲染路径+transform 已确认；完整元素类型表/顶层分发待补（第33节） |

### Agent 指令

**Agent 1：文本框工具**
```
[通用开头：读 COMMANDER.md + REVERSE_ANALYSIS.md]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析文本框工具：

1. 搜索 "text" / "TextBox" / "TextBlock" / "ContentBlock" 在 defpackage 中
   → 找到文本元素的类（可能是 ContentBlock type="Text"）
2. 搜索 "addBlock" 在 com/myscript/iink/Editor.java 中的调用者
   → 文本块怎么创建？
3. 搜索 "EditText" / "TextInput" / "ime" / "keyboard" 在 defpackage 中
   → 文本输入用什么组件？
4. 搜索 "font" / "fontSize" / "lineHeight" / "paragraph" 在 defpackage 中
   → 文本排版参数
5. 确认文本与笔画的关系：
   - 文本是 op 流中的一种元素？还是独立存储？
   - 文本和笔画能一起被选中/移动/缩放吗？
   - 文本渲染是在哪个层？（Canvas drawText？还是独立 View？）
6. 搜索 "CONVERT_TO_TEXT" / "handwritingToText" 在 defpackage 中
   → 手写转文字的实现

目标：文本元素的完整模型（创建/编辑/渲染/持久化/与笔画交互）。
输出：写入 REVERSE_ANALYSIS.md 第 30 节。
```

**Agent 2：图片插入与标注**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析图片功能：

1. 搜索 "addImage" / "ImageBlock" / "image" 在 defpackage 中
   → 图片元素的类
2. 搜索 "camera" / "photo" / "capture" 在 defpackage 中
   → 拍照插入的流程
3. 搜索 "import" / "pdf" / "document" 在 com/gingerlabs/notability/ui/fileimport/ 中
   → PDF/文件导入
4. 确认图片与笔画的关系：
   - 图片是 op 流中的元素？
   - 图片能被选中/移动/缩放/裁剪吗？（selection_menu 有 CROP）
   - 图片上能直接写字吗？（标注层）
   - 图片和笔画的层级关系（z-order）
5. 搜索 "NoteAsset" / "assetHash" 在 defpackage 中
   → 图片资源的存储方式（内嵌？哈希引用？）
6. 搜索 "libtiff" / "tiff" 在 defpackage 中的使用
   → TIFF 用于什么？（页面快照？缩略图？）

目标：图片元素的完整模型 + 与笔画的交互 + 资源存储。
输出：写入 REVERSE_ANALYSIS.md 第 31 节。
```

**Agent 3：录音 + 时间锚点**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析录音功能：

1. 搜索 com/gingerlabs/notability/feature/note/toolbox/audio/ 下所有文件
   → 录音服务的结构
2. 搜索 "RecordingForegroundService" 的实现
   → 前台录音服务怎么工作
3. 搜索 "audioLinked" 在 defpackage 中：
   - BezierStrokeContent 有 audioLinkedAlpha / audioLinkedProgress / audioLinkedTruncatedPath
   - 这些字段怎么用？（笔画与录音时间关联）
4. 搜索 "playback" / "replay" / "timeline" 在 defpackage 中
   → 回放时笔迹怎么动画显示？
5. 搜索 "transcription" 在 com/gingerlabs/notability/data/transcription/ 中
   → 音频转文字的实现
6. 确认录音与笔记的数据关联：
   - 录音文件怎么存？（NoteAsset？独立文件？）
   - 时间戳怎么和笔画关联？（笔画创建时间 = 录音进度？）
   - SyncedNoteMetadata.hasRecordings 的作用

目标：录音-笔记关联机制 + 回放动画 + 转文字。
输出：写入 REVERSE_ANALYSIS.md 第 32 节。
```

**Agent 4：共享抽象层地图**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中找出所有功能共享的抽象层：

1. 元素类型枚举：
   - 搜索所有继承自同一基类的元素（笔画/文本/图片/形状 的共同父类）
   - 搜索 "elementType" / "content_type" / "ulc" / "c9e" 在 defpackage 中
   - 列出完整的元素类型枚举

2. op 流顶层分发：
   - 搜索 "o6e" / "j3c" / "applyOp" / "handleOp" 在 defpackage 中
   - 搜索 "opCode" / "opType" / "OpKind" 在 defpackage 中
   - 尝试找到 op 类型枚举（createPage/addElement/removeElement/transform/...)

3. 渲染层接口：
   - 所有元素怎么统一渲染？（都走 pzf？还是有分发器？）
   - 搜索 "l78"（Renderer 接口）的实现类
   - z-order / 层级怎么管理？

4. transform 矩阵：
   - 搜索 "zy7"（transform 序列化）的使用者
   - 移动/旋转/缩放是统一的 transform 还是每种元素单独处理？

5. 持久化统一接口：
   - 所有元素都走 op 流？还是有些走独立表？
   - FlatBuffers 的根 table 是什么？

目标：画出完整的共享抽象层架构图（元素基类 + op 流 + 渲染接口 + transform）。
输出：写入 REVERSE_ANALYSIS.md 第 33 节。
```

---

## 📅 Day 3 计划 — Fallback 与条件分支全扫描

> 目标：找出所有「如果 X 则走 A，否则走 B」的分支，避免移植时踩坑。
> 原则：每个条件分支都记录「触发条件 + A路径 + B路径 + 影响」。

### 任务队列

| # | 任务 | 具体目标 | 状态 |
|---|------|---------|------|
| 1 | **渲染 fallback 全图** | GPU/CPU 分支、SDK 版本分支、硬件加速检测、异常回退 | ✅ RuntimeShader API33+；scratch 快速路径 API34+；HardwareBuffer usage 降级（第26节） |
| 2 | **输入 fallback** | 无压感设备怎么办？无倾斜怎么办？触摸 vs 笔的切换逻辑 | ✅ `hda.v()`：无能力字段=-1，tool type 映射已确认（第27节） |
| 3 | **笔刷行为 fallback** | 压感缺失时的默认值、形状识别失败时的回退、笔刷不支持时的降级 | ✅ 识别失败保留手画+置信度合并+边界检查（第28节） |
| 4 | **功能开关/Feature Flag** | 所有 fa4 FeatureFlag 枚举、设置项、A/B 实验开关 | ✅ qa4机制+67项枚举+远程jnb配置（第29节） |

### Agent 指令

**Agent 1：渲染 fallback 全图**
```
[通用开头：读 COMMANDER.md + REVERSE_ANALYSIS.md]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中扫描所有渲染相关的条件分支：

1. 读 defpackage/uaa.java（PencilSplatRenderer）：
   - GPU vs CPU 的判断条件是什么？（SDK版本？硬件加速？RuntimeShader可用性？）
   - 如果 RuntimeShader 编译失败会怎样？
   - drawVertices 不支持时的回退？

2. 读 defpackage/in.java 构造函数（渲染器选择）：
   - getUseHighLatencyRenderHelper() 什么时候为 true？
   - SDK>=33 判断的具体条件？
   - 如果 SurfaceControl 创建失败会怎样？

3. 读 defpackage/vd1.java / kd1.java / w20.java：
   - HardwareBuffer 的固定 format 与 usage flags 选择（不要把 usage 常量误认成像素格式）
   - RenderNode 录制失败的处理
   - 渲染线程崩溃的恢复

4. 搜索 "fallback" / "degrade" / "unsupported" / "isHardwareAccelerated" 在 defpackage 中

目标：画出完整的渲染 fallback 树（每个分支点 + 条件 + 两条路径）。
输出：写入 REVERSE_ANALYSIS.md 第 26 节。
```

**Agent 2：输入 fallback**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中扫描输入相关的条件分支：

1. 读 defpackage/hda.java 的 `t()/v()` 与 cu5.java：
   - 无压感/倾斜/方位角能力时 AndroidX Ink StrokeInput 使用什么 sentinel？
   - 触摸、笔、橡皮笔尾和鼠标如何映射？
   - 历史 MotionEvent 与 predicted MotionEvent 如何分别加入批次？

2. 搜索 "getToolType" / "TOOL_TYPE" 在 defpackage 中的分支：
   - 不同 toolType 走什么不同的渲染路径？
   - ERASER toolType 是直接触发擦除还是切换工具？

3. 搜索 "getPressure" 返回 0 或 1 时的处理：
   - 压感=0 是抬笔还是无压感设备？怎么区分？
   - 压感=1 是最大压力还是无压感设备的默认值？

4. 搜索 "hasTiltInfo" / "tilt" / "orientation" 的条件判断：
   - 无倾斜数据时铅笔渲染怎么降级？

5. 搜索 "hover" / "HOVER" 在 defpackage 中：
   - 笔悬停（未触碰屏幕）时有没有预览/光标？

目标：完整的输入 fallback 表（设备能力 × 处理路径）。
输出：写入 REVERSE_ANALYSIS.md 第 27 节。
```

**Agent 3：笔刷行为 fallback**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中扫描笔刷行为的条件分支：

1. 形状识别失败时：
   - b90 检测器置信度不足时怎么办？（保留原始手画路径？）
   - 搜索 b90 的调用者，看返回值判断逻辑
   - 多个形状同时匹配时选哪个？

2. 笔刷不支持时：
   - 搜索 "unsupported" / "not supported" / "unavailable" 在 defpackage 中
   - 特定设备不支持某笔刷时的降级策略？

3. 压感异常时：
   - pressure > 1.0 或 < 0 的处理（clamp？忽略？）
   - 搜索 "min" / "max" / "clamp" / "coerce" 在 xaa/s78 中

4. PencilSplat 生成异常：
   - 点数太少（只有1-2个点）时怎么处理？
   - 极快速滑动（点间距很大）时的处理？
   - 搜索 xaa 中的边界条件判断

5. 渲染异常：
   - Path 为空/null 时的处理
   - 搜索 "isEmpty" / "== null" / "!= null" 在 pzf/uaa 中的防御性检查

目标：完整的异常/边界处理表（场景 × 处理方式）。
输出：写入 REVERSE_ANALYSIS.md 第 28 节。
```

**Agent 4：Feature Flag 全枚举**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中找出所有功能开关：

1. 读 defpackage/fa4.java（FeatureFlag 枚举）：
   - 列出所有 flag 名称和序号
   - 每个 flag 控制什么功能？

2. 搜索 "isEnabled" / "getBoolean" / "featureFlag" 在 defpackage 中：
   - 哪些功能是可开关的？
   - 默认值是什么？

3. 搜索 "BuildConfig" / "DEBUG" / "EXPERIMENTAL" 在 defpackage 中：
   - 有没有实验性功能的代码？

4. 搜索 "RemoteConfig" / "remote_config" / "firebase" 在 defpackage 中：
   - 有没有服务端控制的 A/B 实验？
   - 哪些行为可能被远程切换？

5. 搜索设置项（SharedPreferences / DataStore）：
   - 用户可配置的选项有哪些？
   - 哪些设置会影响渲染行为？

目标：完整的 Feature Flag 表 + 用户设置表 + 远程开关表。
输出：写入 REVERSE_ANALYSIS.md 第 29 节。
```

---

## 📅 Day 2 计划 — 笔种补全 + 工具系统深挖

> 目标：把所有书写工具的算法全部抽出来，包括形状识别、选区工具、变换操作。
> 完成后，「怎么写 + 怎么画 + 怎么选 + 怎么变」就全齐了。

### 任务队列

| # | 任务 | 具体目标 | 状态 |
|---|------|---------|------|
| 1 | **钢笔/荧光笔压感行为** | 确认 FIXED_WIDTH vs Taper 的渲染分支，压感是否影响宽度 | 🟡 Taper→VARIABLE_WIDTH、逐点因子存在；因子生成来源待补（第23/35节） |
| 2 | **轮廓算法** | 普通可变宽度 ink 如何从中心线生成填充轮廓 | 🟡 `w4a.b()` 已定位并实际调用；混淆变量语义和完整伪代码待恢复 |
| 3 | **形状工具（停笔识别）** | 画圆停笔→自动变圆、画三角→变多边形、画线→变直线。触发条件、动画、参数 | ✅ 触发链+cxe回调+开关（第24节） |
| 4 | **选区工具（套索/矩形）** | 自由套索 + 矩形选择，选中后的操作（移动/旋转/缩放/复制/删除/层级） | ✅ Drawn/Lasso模型+22项菜单（第25节） |
| 5 | **op 流顶层分发** | op 类型枚举、页面增删、op 应用协程 | ⚠️ 维持深水区，需 jadx-gui 交互追踪 o6e |

### Agent 指令

**Agent 1：钢笔压感 + 轮廓算法**
```
[通用开头：读 COMMANDER.md + REVERSE_ANALYSIS.md]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中确认钢笔/荧光笔的压感行为：

A) 压感与宽度：
1. 搜索 "FIXED_WIDTH" 和 "Taper" 在 defpackage 中的使用（z21.java 是 brushStyle 枚举）
2. 读 defpackage/pzf.java 的 g() 方法（钢笔渲染），看 strokeWidth 怎么设置
3. 搜索 "brushWidth" / "widthSize" 在渲染链中是否随压感变化
4. 搜索 "BrushBehavior" / "SizeBehavior" / "pressure" 在 androidx/ink/brush/ 下
5. 确认：钢笔宽度是固定的？还是压感变化的？Taper 是什么效果（起笔细→中间粗→收笔细？）

B) 轮廓算法：
1. 读 defpackage/w4a.java 的 a() 方法
2. 读 defpackage/h76.java 的 W() 方法
3. 确认：宽度变化 → 上下轮廓线的具体算法（垂直偏移？法向量？）
4. 轮廓线是用于渲染还是用于擦除命中检测？

目标：确认钢笔是否有压感宽度 + Taper 渲染公式 + 轮廓算法。
输出：写入 REVERSE_ANALYSIS.md 第 23 节。
```

**Agent 2：形状工具（停笔识别）**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析形状识别工具：

背景：第 17 节已确认形状识别系统（b90 检测器：直线/椭圆/多边形）。
现在要搞清楚「停笔触发」的完整交互流程：

1. 搜索 "hold" / "pause" / "timeout" / "delay" / "linger" 在 defpackage 中
   → 找到停笔多久触发形状识别（时间阈值）
2. 搜索 b90 的调用者（谁触发了形状检测？）
3. 搜索 "ShapeOnHold" / "shape_on_hold" 在 com/myscript/iink/ 中
4. 确认触发条件：
   - 停笔多久？（500ms？1000ms？）
   - 是抬笔前触发还是抬笔后触发？
   - 触发后是替换当前笔画还是叠加？
5. 搜索形状识别后的「吸附」动画（从手画路径→完美形状的过渡）
6. 确认支持哪些形状：圆/椭圆/直线/三角/矩形/多边形/箭头？
7. 搜索 "az5"（多边形）和 "wv8"（椭圆）的创建路径

目标：还原完整的「停笔→识别→替换」流程 + 时间参数 + 支持形状列表。
输出：写入 REVERSE_ANALYSIS.md 第 24 节。
```

**Agent 3：选区工具 + 变换操作**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析选区工具：

A) 选区创建：
1. 搜索 "SELECTION" 在 zy5（工具枚举）相关代码中的使用
2. 搜索 "lasso" / "marquee" / "select" / "selectionIsFreehand" 在 defpackage 中
3. 确认：套索选区（自由画圈）和矩形选区（拖拽框选）的实现
4. 选中判定：笔画与选区的相交检测算法（bounding box? 精确路径?）

B) 选中后操作：
1. 搜索 "move" / "rotate" / "scale" / "transform" / "copy" / "paste" / "duplicate" 在 defpackage 中
2. 搜索 "ContentSelection" 在 com/myscript/iink/ 中的使用
3. 搜索 "send_forward" / "send_backward" / "send_to_front" / "send_to_back"（层级）
4. 搜索 "group" / "ungroup" / "lock" / "unlock"
5. 确认变换操作的实现：
   - 移动：偏移量应用到选中笔画的所有点？
   - 旋转：围绕中心点旋转矩阵？
   - 缩放：等比/非等比？
   - 复制：深拷贝笔画数据？

C) 选区 UI：
1. 搜索选中后的边框/控制点绘制（bounding box + 旋转手柄）
2. 搜索 "selection_menu" 相关字符串引用

目标：还原选区工具的完整交互流程 + 变换算法。
输出：写入 REVERSE_ANALYSIS.md 第 25 节。
```

**Agent 4：op 流顶层分发**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析 op 流顶层结构：

1. 搜索 "o6e" 类（op 应用协程）或 "j3c"（op 处理链）
2. 搜索 "opType" / "op_type" / "OpKind" 在 defpackage 中
3. 搜索 "createPage" / "insertPage" / "deletePage" / "addStroke" / "removeStroke" 在 defpackage 中
4. 搜索 ClientOp 表的 op BLOB 怎么解码（FlatBuffers 的根 table 是什么）
5. 确认 op 类型枚举完整列表（createNote/addPage/deletePage/insertStroke/transformStroke/...)
6. 确认页面管理：多页笔记的页面列表怎么存（数组？链表？顺序字段？）

目标：还原 op 类型枚举 + 页面数据结构。
输出：写入 REVERSE_ANALYSIS.md 第 21 节（更新）。
```

---

## 📅 Day 1 计划 — 深度侦察：手感三件套

> 目标：搞透「平滑 + 质感 + 延迟」，这三个决定手写体验的核心。
> 方法：继续批量 Agent，每个专攻一个点。

### 🔴 手感三件套（核心）

| # | 任务 | 具体指令 | 状态 |
|---|------|---------|------|
| 1 | **笔画平滑算法** | 追踪输入点→Force smoothing→三次贝塞尔分段拟合 | 🟡 主体已还原，动态容差变量和全部工具分支待补（REVERSE 第17节） |
| 2 | **PencilSplat 生成逻辑** | StrokeInput(pressure,tilt,orientation) → faa(x,y,rotation,scale,opacity) 的映射函数。在 esd/nq5/s78 中找压感曲线。 | ✅ 完整公式（第18节）LCG随机+椭圆盘+5次方缓动 |
| 3 | **低延迟渲染机制** | CanvasFrontBufferedRenderer (vd1/kd1) 的双缓冲逻辑、RenderNode 调度、增量渲染区域计算。 | ✅ 双SurfaceControl+双RenderNode（第19节） |

### 🟡 补充分析（并行）

| # | 任务 | 具体指令 | 状态 |
|---|------|---------|------|
| 4 | **AndroidX Ink 官方文档** | 联网搜索 AndroidX Ink 的 Brush/Stroke/Mesh 文档，理解其笔刷模型设计，对比 Notability 的用法 | ✅ 1.0稳定版+模块对照（第20节） |
| 5 | **op 流 / 笔记持久化** | ClientOp 表的 BLOB 格式、FlatBuffers 编解码、页面增删操作 | 🟡 元素schema已还原（第21节），顶层分发待挖 |
| 6 | **工具栏交互逻辑** | 工具切换状态机、笔刷参数面板、颜色/粗细选择器 | ✅ Brush模型+工具枚举（第22节） |

### Agent 指令模板

**Agent 1：笔画平滑**
```
[通用开头：读 COMMANDER.md + REVERSE_ANALYSIS.md]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中追踪普通笔迹平滑算法：

1. 读 `ms1.b()`：输入批次、ForceSmootherConfig 和动态容差计算。
2. 读 `sqh.f()/g()/h()`：分段、最小二乘三次贝塞尔、最大误差判断和二分最长区间。
3. 读 `gp2`：确认 `CubicCurve(p0,p1,p2,p3)` 的求值和拆分。
4. 区分普通平滑与 `b90/nzf` 形状识别，不能混成同一算法。
5. 确认不同工具、笔宽和 zoom 如何影响容差。

目标：还原完整的平滑算法伪代码。
输出：算法步骤 + 关键参数 + 伪代码，写入 REVERSE_ANALYSIS.md。
```

**Agent 2：PencilSplat 生成**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中追踪 PencilSplat 点的生成：

1. 读 defpackage/faa.java（PencilSplat 点：x,y,rotation,scale,opacity）
2. 搜索谁创建 faa 实例（grep "new faa" 或 "faa("）
3. 追踪从 StrokeInput 到 faa 列表的转换链（可能在 esd/nq5/s78 中）
4. 找压感→scale 的映射函数（线性？指数？分段？）
5. 找 splat 点间距的计算（固定距离？速度相关？）
6. 找 rotation 的计算规则（随机？方向相关？倾斜相关？）

目标：还原 pressure/tilt/orientation → scale/opacity/rotation 的完整映射曲线。
输出：映射公式 + 参数值 + 伪代码，写入 REVERSE_ANALYSIS.md。
```

**Agent 3：低延迟渲染**
```
[通用开头]

任务：在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析低延迟渲染：

1. 读 defpackage/vd1.java（CanvasFrontBufferedRendererV33）
2. 读 defpackage/kd1.java（CanvasFrontBufferedRendererV29）
3. 读 defpackage/jd1.java（高延迟模式对比）
4. 搜索 "RenderNode" / "RecordingCanvas" / "HardwareBuffer" 在 defpackage 中
5. 确认：
   - 双缓冲怎么工作？（前缓冲/后缓冲交换机制）
   - 增量渲染区域怎么计算？（只重绘笔画周围？）
   - 历史点批量插入怎么降低延迟？
   - 渲染线程模型（主线程 vs 独立线程）

目标：还原完整的低延迟渲染架构。
输出：线程模型图 + 缓冲机制 + 增量策略，写入 REVERSE_ANALYSIS.md。
```

**Agent 4：AndroidX Ink 文档研究**
```
[通用开头]

任务：联网搜索并整理 AndroidX Ink 的官方文档：

1. 搜索 "AndroidX Ink library" / "androidx.ink brush" / "androidx.ink strokes" 官方文档
2. 理解 Brush 模型：BrushFamily → BrushCoat → BrushTip → BrushBehavior
3. 理解 Stroke 模型：StrokeInput → InProgressStroke → Mesh
4. 理解渲染：CanvasMeshRenderer / StrokesView / StrokesController
5. 对比 Notability 的用法（REVERSE_ANALYSIS.md 第4节）：哪些是标准用法，哪些是自研扩展

目标：整理 AndroidX Ink 架构概览 + Notability 的自定义扩展点。
输出：架构对比表 + 鸿蒙复现要点，写入 REVERSE_ANALYSIS.md。
```

---

## 📅 Day 0 批量分析（已完成 ✅，属于预备侦察）

> 目标：一天内把 P0 + P1 的关键信息全部挖出来。
> 方法：开多个 AI Agent 对话，每个给一个明确任务，并行推进。
> 原则：先做了再说，路遥慢慢。每个 Agent 的输出都贴回 REVERSE_ANALYSIS.md。

### Agent 1：资源猎手（解压 + 找图）

**给 Agent 的指令：**
```
解压以下两个 APK（本质是 zip），列出所有文件，找出笔刷/纹理/纸张相关的资源：

1. c:\Users\Cisco He\Desktop\Notability\Notability\com.gingerlabs.notability.apk
   → 重点看 assets/ 目录下有没有 brush/stamp/pen/pencil/texture/paper 相关文件
   → 也看 res/drawable* 里有没有相关图片

2. c:\Users\Cisco He\Desktop\Notability\Notability\config.xxhdpi.apk
   → 这个包全是高密度图片，列出所有文件名，找笔刷纹理

把找到的文件路径和文件名全部列出来。
如果有 .png/.webp 图片，描述其尺寸和外观。
```

**期望产出**: 笔刷纹理图列表 + 纸张背景图（如果有）

---

### Agent 2：数据模型猎人（笔画结构）

**给 Agent 的指令：**
```
在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析笔记的笔画数据模型：

1. 搜索 defpackage 中名字含 stroke/ink/path/point 的类
2. 查看 com/gingerlabs/notability/data/note/ops/ 下所有文件
3. 搜索 FlatBuffers 相关：grep "flatbuffers" 或 "Table" 或 "ByteBuffer" 在 data/note/ 下
4. 查看 com/gingerlabs/notability/core/flatbuffers/ 下的 ValidationException.java
5. 搜索 defpackage 中 vm4.java（之前在 lj8.java 里看到它代表一个笔画点，有 f=force, c()/e()/f() 方法）

目标：还原出一个 stroke 的完整数据结构（哪些字段、什么类型、怎么序列化）。
```

**期望产出**: 笔画数据模型定义（字段 + 类型 + 存储方式）

---

### Agent 3：渲染链路追踪

**给 Agent 的指令：**
```
在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中追踪渲染调用链：

1. 在 com/myscript/iink/GLRenderer.java 中找：
   - 它实现了什么接口？（应该是 ICanvas）
   - configureBrush() 方法的完整逻辑
   - drawStrokeWithExtraBrush() 的实现

2. 搜索谁创建了 GLRenderer 实例（grep "new GLRenderer" 或 "GLRenderer("）

3. 搜索谁调用了 Renderer.drawModel / drawModelAsync

4. 搜索 IRenderTarget 的实现类（这是 GLRenderer 的上层容器）

5. 查看 com/myscript/iink/Renderer.java 的完整代码（188行）

目标：画出从「用户触摸」到「像素上屏」的完整调用链。
```

**期望产出**: 渲染管线调用图

---

### Agent 4：输入事件 + 橡皮擦

**给 Agent 的指令：**
```
在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析：

A) 输入事件处理：
1. 搜索 "MotionEvent" 在 defpackage 中的使用（找 onTouchEvent 或 dispatchTouchEvent）
2. 搜索 "PointerEvent" 的创建位置（new PointerEvent 或 .down( / .move( / .up(）
3. 搜索 "getPressure" 或 "pressure" 或 "getAxisValue"（压感采集）
4. 搜索 "AXIS_TILT" 或 "AXIS_ORIENTATION"（倾斜采集）

B) 橡皮擦：
1. 搜索 "eraser" 或 "ERASER"（不区分大小写）
2. 搜索 PointerType 枚举（com/myscript/iink/PointerType.java）
3. 搜索 "erase" 在 Editor.java 中的实现
4. 确认：是像素擦除（blend mode）还是笔画擦除（删除整条 stroke）？还是两种都有？

目标：输入事件映射表 + 橡皮擦工作方式。
```

**期望产出**: 输入映射关系 + 橡皮擦机制确认

---

### Agent 5：纸张模板 + 页面管理

**给 Agent 的指令：**
```
在 c:\Users\Cisco He\Desktop\Notability\decompiled\sources 中分析：

A) 纸张模板：
1. 搜索 "grid" / "rule" / "dots" / "plain" / "paper" / "template"（不区分大小写）
2. 搜索 "core_paper" 相关引用（strings.xml 里有 core_paper__grid 等）
3. 找到纸张背景的绘制代码或资源引用
4. 确认：是代码绘制还是预制图片？

B) 页面管理：
1. 查看 com/gingerlabs/notability/data/note/state/ 下的文件
2. 搜索 "page" 相关类（pageCount, addPage, deletePage, pageSize）
3. 搜索 "A4" / "letter" / "tabloid" 看纸张尺寸怎么定义
4. 确认：多页笔记的数据结构（页面列表？每页独立？）

目标：纸张模板实现方式 + 多页笔记数据组织。
```

**期望产出**: 纸张系统 + 页面管理模型

---

### ~~Agent 6：IDA 分析 libink.so~~ → 已取消 ✅

> **2026-08-02 已解决（针对手写核心）**: 用 dump_exports.py 确认 libink.so = AndroidX Ink，
> libgraphics-core.so = AndroidX Graphics 支持库。25 个 so 可归为第三方/运行时；`libglmath.so` 是应用专用 LaTeX JNI，来源归属仍不能仅凭包名断定。手写核心无需继续盲扫全部 so。
> 工具保留在 `dump_exports.py`，将来如果需要看其他 so 可以用。

---

### 执行顺序建议

```
并行批次 1（不需要前置知识，直接挖）：
  → Agent 1（资源猎手）
  → Agent 2（数据模型）
  → Agent 5（纸张+页面）

并行批次 2（需要批次1的结果辅助理解）：
  → Agent 3（渲染链路）
  → Agent 4（输入+橡皮擦）

可选/独立：
  → ~~Agent 6（IDA）~~ 已取消，所有so均为已知库
```

### 收工检查清单

- [x] 每个 Agent 的输出都整理进 REVERSE_ANALYSIS.md
- [x] COMMANDER.md 任务队列中对应的 ⬜ 改为 ✅
- [x] 新发现的疑问写入「阻塞/疑问」区
- [x] 更新「上次进度」
- [x] 如果发现新的分析方向，追加到任务队列（已追加：笔画平滑算法 / PencilSplat 生成 / op 流解析）

> ✅ 2026-08-02 Day 2 批量分析已全部完成，5 个 Agent 任务均有产出。

---

## 阻塞 / 疑问

> 分析过程中遇到的困惑、死胡同、需要验证的假设，记在这里。

- ⚠️ **op 流顶层分发**：ClientOp BLOB 的 op 类型枚举（createPage/insertStrokes 等）未定位，
  需 jadx-gui 交互式追踪 o6e（op 应用协程）或 j3c 相关 op 处理链。
- 🟡 **普通可变宽度轮廓**：`w4a.b()` 已确认是实际 ink 轮廓路径，仍需恢复完整伪代码和 `fc0.e()` 生成链。
- 🟡 **普通平滑容差**：Force smoothing 与三次贝塞尔拟合已确认，动态容差变量语义和全部工具分支待补。
- 🟡 **鸿蒙低延迟**：预测点/帧加速 API 已确认，但端到端指标必须在目标设备上量测。
- 🟡 **图片元素与共享抽象层**：NoteAsset、c9e 基类、三条 ink 渲染路径已定位，但图片具体元素、裁剪/z-order 和完整 c9e 类型表待补。
- 🟡 **录音时间锚点**：服务与 audioLinked 字段已定位，时间戳来源和进度赋值链待补。
- 🟡 **UI 精确视觉 token**：根入口、双层路由、响应式布局和主要组件已定位；主题色板、字体/圆角/阴影、弹层锚点与动画曲线仍需动态量测。
- ✅ 已解：PencilSplat 公式、Android 低延迟渲染架构、形状识别主体（见 REVERSE_ANALYSIS 第 18/19/24 节）。

---

## 工具速查

### 工作区目录结构
```
Notability/
├── COMMANDER.md              ← 你在这里（作战计划）
├── REVERSE_ANALYSIS.md       ← 知识库（所有发现）
├── LOGIN_BYPASS_RETROSPECTIVE.md ← v14 启动/登录状态机完整复盘
├── PROJECT_HANDOVER.md       ← 项目交接与开工闸门
├── ENVIRONMENT_SETUP.md      ← ADB/Python/Frida 复现环境
├── START_PROMPTS.md          ← 当前阶段任务模板
├── reports/                  ← 独立报告；命名/证据/汇总规则见 README.md
├── dump_exports.py           ← ELF导出表解析工具
├── Notability.xapk           ← 原始 XAPK (197MB，可备份后删除)
│
├── Notability/               ← XAPK 解压出的原始分包 APK
│   ├── manifest.json
│   ├── com.gingerlabs.notability.apk   (base)
│   ├── config.arm64_v8a.apk
│   ├── config.en.apk
│   └── config.xxhdpi.apk
│
├── decompiled/               ← jadx 反编译输出（核心分析对象）
│   ├── sources/              ← Java 源码（14000+ 类）
│   └── resources/            ← 资源 + assets
│       ├── assets/conf/      ← MyScript 识别配置
│       ├── assets/glmath/    ← LaTeX 字体
│       └── res/              ← Android 资源
│
├── arm64_extracted/          ← ARM64 so 库（功能身份已分析；25 个第三方/运行时 + 1 个应用专用 LaTeX JNI）
│   └── lib/arm64-v8a/       ← 26 个 .so
│
├── xxhdpi_extracted/         ← 高密度图片（无 PencilSplat；含 UI、登录插画和小组件资源）
│   └── res/
│
├── frida_scripts/            ← 本地动态验证脚本（当前成功版本 bypass_login_v14.py）
├── Screenshot/               ← v14 资料库/编辑器运行时截图与历史排障图
│
└── jadx-1.5.6/               ← jadx 工具
    └── bin/jadx-gui.bat
```

### 分析状态总结
| 内容 | 状态 | 结论 |
|------|------|------|
| Java 代码反编译 | ✅ 完成 | 所有私有逻辑在这里 |
| SO 库身份识别 | ✅ 功能分类 | 25 个第三方/运行时；`libglmath.so` 为应用专用 LaTeX JNI，所有权未由 JNI 命名证明 |
| xxhdpi 资源 | ✅ 完成 | 无 PencilSplat；包含 UI、登录插画和小组件资源 |
| base APK assets | ✅ 提取 | MyScript配置+LaTeX字体+OCR模型 |
| 笔刷纹理图片 | ✅ 找到 | `drawable-nodpi/ui_renderer__pencil_splat.png`（已确认的铅笔 splat 纹理） |
| 渲染架构 | ✅ 修正 | AndroidX Ink + 自研 PencilSplatRenderer，无 OpenGL |
| 笔画数据模型 | ✅ 还原 | s78 + PencilSplat + WetMirrorRenderSpec |
| 橡皮擦 | ✅ 确认 | PARTIAL(像素) + WHOLE(整条) 双模式 |
| 纸张模板 | ✅ 确认 | 程序化绘制 + REPEAT 平铺，8种尺寸 |
| 本地数据库 | ✅ 还原 | 全部 Room 表结构 |
| 实时输入链 | ✅ 纠正 | `hda/cu5` 生成 AndroidX Ink StrokeInput；`gc8/jma` 属于 Compose 指针事件 |
| 普通笔迹平滑 | 🟡 主体还原 | Force smoothing + 最小二乘三次贝塞尔分段拟合；容差语义待补 |
| 普通可变宽度 | 🟡 主体还原 | Taper→VARIABLE_WIDTH，`w4a.b()` 构造轮廓；逐点因子来源待补 |
| HarmonyOS 低延迟 | 🟡 待实测 | 华为 SDK 有预测点/帧加速能力；RenderNode 非 SurfaceControl 直接等价物 |
| HarmonyOS 纹理渲染 | ✅ 能力边界 | Canvas2D、ShaderEffect(API20+) 与 XComponent/OpenGL ES 三层路线 |
| 启动/登录状态机 | ✅ 本地验证 | `un7`/`hp8`/`hnf`/`aq8` 静态闭环，v14 导航栈进入 `o77`；冷启动需重新注入 |
| UI 根入口与导航 | 🟡 主干闭环 | `MainActivity→ComposeView→s4g.d`；主栈 `o77→f89`、内部栈 `zz8`，资料库断点和编辑器主要组件已定位（第39节） |
| 图片/录音高级元素 | 🟡 部分还原 | NoteAsset 与 audioLinked 字段已定位，具体元素和时间映射待补 |
| en 语言包 | ➖ 不需要 | 仅英文字符串 |

### 工具命令
| 工具 | 用途 | 命令/路径 |
|------|------|----------|
| jadx-gui | 可视化浏览反编译代码 | `jadx-1.5.6\bin\jadx-gui.bat` |
| jadx CLI | 命令行反编译 | `& "jadx-1.5.6\bin\jadx.bat" -d output input.apk` |
| dump_exports.py | 解析 so 导出函数 | `python dump_exports.py [--all]` |
| REVERSE_ANALYSIS.md | 知识库 | 本工作区根目录 |

### jadx-gui 搜索技巧
- `Ctrl+Shift+F` 全局搜索
- 搜 `stroke` / `brush` / `pen` / `eraser` 找手写相关
- 搜 `FlatBuffer` / `table` 找数据模型
- 搜 `grid` / `rule` / `dots` / `paper` 找纸张模板
- 在 `defpackage` 包里按引用追踪（右键 → Find Usage）

---

## 心态提醒

- 🐢 **不求快**：每次搞懂一个小点就是胜利
- 🗺️ **不求全**：不需要理解 14000 个类，只需要理解核心链路
- ❌ **允许死胡同**：走错了记下来，换条路
- 📝 **随时记录**：好记性不如烂笔头，发现就写进 REVERSE_ANALYSIS.md
- 🎯 **聚焦 P0**：手写核心搞懂了，其他都是锦上添花
