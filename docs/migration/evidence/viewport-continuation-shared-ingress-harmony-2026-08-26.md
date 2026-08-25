# Harmony 证据 — Phase 468 视口续体共享租约修复

## 变更位置

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
  - `schedulePdfRasterRefresh()` 新增共享导入与历史租约拒绝。
  - `saveViewportState()` 普通写入拒绝两类租约；`allowDisposedFinalSave=true` 终存豁免。
  - 捏合与平移的 end/cancel 回调在共享导入期不安排零延迟 PDF 重栅格。
- `docs/migration/replays/d02-viewport-save-lifecycle-bound.mjs`
  - 相邻断言同步锁定终存豁免与普通写租约守卫。

## 静态验证

- 新增焦点 Replay：
  `docs/migration/replays/d02-viewport-continuation-shared-ingress-bound.mjs`
  输出 `TOTAL=10 FAILED=0`。
- 相邻 PDF 可见区栅格 Replay 通过；视口保存生命周期 Replay 同步后通过；视口范围 Replay
  与 Phase 467 粘贴 Replay 保持通过。
- ArkTS 检查 `NoteCanvasView.ets` 无错误；仅既有 unused/deprecation 信息。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。
