# ADR-0697：原版 Zoom 自动前进区宽持久化（o59.r）

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0695/ADR-0696（Zoom View 移植）、
  `phase-749-original-zoom-advance-width-persist.md`

## 背景

`o59.r = eua("zoomViewAdvanceRegionWidthDp")` 是原版 Preferences DataStore
键；`g0j` advance_tab 拖拽 → `ahg.setAdvanceRegionWidth(F)` → `n27` case 2
`tk8.g` 逐次写库，`bc7` case 27 随编辑器设置读回。即用户调整的自动前进区
宽度**跨会话保留**（默认 `180.0f`）。

Phase 747 的 Harmony 实现把宽度放在 `NoteCanvasView` 内存 `@State`，每次
挂载回退 180vp——缺失跨会话记忆。

## 决定

1. `EditorSettingsStore` 新增同名键 `zoomViewAdvanceRegionWidthDp`（number）
   与 `DEFAULT_ZOOM_ADVANCE_WIDTH_DP=180`，沿用既有 mutex + flush 失败
   回滚范式（新增通用 `getNumberPref`/`saveNumberPref`）。
2. `EditorViewModel` 新增 `zoomAdvanceWidthDp`，随编辑器设置块加载；
   `setZoomAdvanceWidthDp` 走 `enqueueSave` + 失败回滚。
3. `NoteCanvasView.initZoomSourceRect` 挂载时同步 VM 值；
   `onAdvanceRegionCommit`（拖拽 onActionEnd）调 VM setter，失败回滚本地
   @State。
4. `NoteZoomView` advance_tab 手势补 `onActionStart`（钉住起点宽）与
   `onActionEnd`（提交点）——顺带修复 offsetX 累计量被逐帧重复相减的
   拖拽漂移。

## 近似登记

原版 `setAdvanceRegionWidth` 逐帧写 DataStore；Harmony 仅在拖拽提交点写
一次。跨会话可观察行为等价（下次挂载读回上次终值），拖动过程不落盘。

## 验证

- `d02-original-zoom-view.mjs` 扩展 pins（持久化键/读回同步/提交点）；
- 全量 Desktop Replay 见提交；
- `note@default` / `note@ohosTest` 双 HAP 构建成功。
