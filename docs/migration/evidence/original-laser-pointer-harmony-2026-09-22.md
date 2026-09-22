# 原版激光笔（Laser Pointer）— Harmony 证据文档

- 日期：2026-09-22
- Phase：572
- 结论：已对齐（瞬态渲染语义完整移植；原版 fade 字段错位的怪癖如实保留）

## 原版证据（decompiled_1.0.3）

### 工具注册 `rz1`

- `rz1.java:1058-1061`：LASER 的 4 档颜色井
  `qb4(0, a6f.R, -1754827, 0)` / `-14776091` / `-12345273` / `-141259`
  （对应 #E53935 红 / #1E88E5 蓝 / #43A047 绿 / 黄），缺省选中第 0 档。
- `rz1.java:1075`：默认托盘
  `u5f(0, 1, a6f.R, 1, w31(-1754827, 15.0f, ...))`——`a6f.R`=LASER
  位于 **Secondary 托盘 index 1**（index 0 为 POINTER，2/3/4 为 Zoom/
  Ruler/REVIEW，POINTER/Zoom/Ruler 未移植），颜色 -1754827、宽度
  固定单档 15pt、无样式井。

### 渲染状态 `zt6` / `du6` / `cu6`

- `zt6.java:21`：`bsd.a(du6(kkf.d(-1754827), 15.0f, cu6.i.a, ...))`——
  渲染状态初值 = 颜色 -1754827、宽 15pt、`showTail` 读 `cu6.i`。
- `cu6.i` = `bu6(true)`：`laser_preferences/show_tail` 缺省 **true**。
- `LaserRenderState` 字段：color、width、showTail、pointerPoint +
  pointerAlpha、tailSegments（进行中队列 P + 已完成段队列 Q）+
  tailAlpha。

### 事件流 `xt6`

- down/move（`qt6`/`rt6`）只更新渲染状态，**不产生持久笔画**——激光
  不进文档模型、不进 undo 栈。
- up：showTail 且 pending 队列可成段 → 收尾入 Q；否则直接清空。
- 取消（`pt6`）→ `zt6.i()` 立即清空全部状态。

### 衰减 `yt6`

- 抬手后协程：`fag.B(500)` 延迟 → `i = 1..31` 每帧 `fag.B(16)` 逐帧
  衰减 alpha → `zt6.i()` 清空。
- **原版怪癖**：fade 循环衰减的是“另一模式”的 alpha 字段（tail 模式
  写 pointerAlpha、no-tail 模式写 tailAlpha），即可见 alpha 实际不随
  帧下降——可见契约等效为“标记不透明驻留约 1 秒后清除”。Harmony
  如实保留该字段错位与全部时序常量。

### 渲染 `ft0` case 22

- tail 段：圆头圆角（round cap/join）描边折线，宽 = `j0(widthPt)`，
  透明度 tailAlpha。
- 指针点：实心圆，半径 width/2，透明度 pointerAlpha。

### 设置 UI `pni`/`uni.a` + `gh9`

- 激光工具设置 = Tail / No Tail 分段开关，写 `show_tail`；
  字符串 `ui_tools__laser`/`laser_tail_label`/`laser_no_tail_label`/
  `laser_tail_mode`/`laser_no_tail_mode`（a11y）。

## Harmony 实现

- `core/adaptation/OriginalLaserPointer.ets`：`OriginalLaserSession`
  状态机（pending/completed 段队列、pointer 点、双 alpha、fade 帧、
  clear），常量与原版逐一对齐。
- `ToolType.LASER = 8`；`EditorViewModel.createDefaultStates` 种子
  `laser`（Secondary 托盘 index 1、-1754827、15pt、MONO）。
- `ToolRepositoryImpl`：LASER 颜色井 4 档、宽度井单档 [15.0]；VM 对
  LASER 不加载宽度井（`supportsBrushControls()` 仍为 false，
  新增 `supportsColorControls()` 仅放行颜色井）。
- `EditorSettingsStore`：`laserShowTail` 布尔键，缺省 true。
- `EditorToolbar`：激光激活时设置面板渲染 Tail/No Tail 分段按钮，
  颜色按钮经 `supportsColorControls()` 对激光开放。
- `NoteCanvasView`：down/move/up 在笔画会话创建前分流到
  `laserSession`；渲染层在 snapGuides 之后叠加瞬态激光；抬手调度
  500ms + 31×16ms fade；`cancelActiveInteraction`/`aboutToDisappear`
  清空会话与计时器。

## 差异登记

- 无功能差异。渲染载体为 ArkUI `CanvasRenderingContext2D`（原版为
  Android `Canvas`），坐标/透明度语义等价。
- 设备级验证（fade 动画流畅度、15pt 物理尺寸、掌触共存）登记于
  `真机验收清单-2026-09-22.md` 手写与画布渲染分组。

## 验证

- fixture `d02-original-laser-pointer.mjs`：50 断言（常量、状态机
  字段、托盘种子、颜色/宽度井、持久化键、UI 接线、瞬态不持久化
  约束、字符串）。
