# ADR-0543：原版激光笔工具移植

## 状态

已实施（Phase 572）

## 背景

原版 `a6f.R` = LASER：Secondary 托盘 index 1 的瞬态指示工具
（`rz1.java:1075`），颜色井 4 档（-1754827/-14776091/-12345273/
-141259）、宽度固定 15pt、无样式井；`laser_preferences/show_tail`
缺省 true（`cu6.i`/`bu6`）。Harmony 此前完全没有激光工具。

激光的核心语义是**瞬态**：`xt6` 的 down/move/up 只更新
`LaserRenderState`，不进文档模型、不进 undo 栈；抬手后 `yt6`
协程 500ms 延迟 + 31×16ms 逐帧衰减，最后 `zt6.i()` 清空。

## 决策

1. 新增 `ToolType.LASER` 与 `core/adaptation/OriginalLaserPointer.ets`
   状态机，如实保留原版字段结构（pending/completed tail 段、
   pointer 点、pointerAlpha/tailAlpha 双字段）与全部时序常量。
2. 默认工具种子：Secondary 托盘 index 1、色 -1754827、宽 15pt
   （POINTER/Zoom/Ruler 未移植，index 语义按原版保留）。
3. 原版 fade 怪癖（衰减写另一模式的 alpha 字段，可见 alpha 实际不降）
   如实保留——可见契约等效“驻留约 1 秒后清除”，不擅自“修复”。
4. VM 新增 `supportsColorControls()`：激光放行颜色井（4 档），
   不加载宽度井（单档 15pt 且无宽度 UI）；`supportsBrushControls()`
   语义不变。
5. `laserShowTail` 偏好经 `EditorSettingsStore` 持久化，工具栏在激光
   激活时渲染 Tail/No Tail 分段开关（原版 `pni`/`uni.a` 同构）。
6. 画布在笔画会话创建前分流激光输入；渲染叠加在 snapGuides 之后的
   瞬态层；取消/页面切换/销毁清空会话与 fade 计时器。

## 差异

- 无功能差异；渲染载体换为 ArkUI Canvas2D。
- 原版 POINTER（index 0）/Zoom/Ruler 工具未移植，托盘 index 仅为
  语义对齐，不保证绝对位置。
- fade 动画帧率、15pt 物理观感、掌触与多点共存等行为仅真机可验，
  已登记 `真机验收清单-2026-09-22.md`。

## 验证

- `d02-original-laser-pointer.mjs`（50 断言）；全套 replay 全绿；
  `note@default` + `note@ohosTest` HAP 构建成功。
