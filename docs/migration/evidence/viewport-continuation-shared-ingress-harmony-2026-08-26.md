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

## Phase 500 增量（2026-08-26）

- 继续补审发现：画布缩放条“-”、“+”和适配宽度按钮已有 `.enabled(!this.photoImportBusy)`
  响应式禁用，但点击直接调用缩放方法，缺少与其他视口入口一致的回调防线。
- 三个回调现在先拒绝 `photoImportBusy`，再执行原步骤缩放或适配宽度。缩放范围、锚点、视口
  保存、PDF 重栅格和手势续体语义不变。
- 扩展既有视口续体专项 Replay 至 `TOTAL=13 FAILED=0`，锁定三项新防线。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。
