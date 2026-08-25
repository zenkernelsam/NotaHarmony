# Harmony 证据 — Phase 466 已打开数学编辑器共享租约修复

## 变更位置

- `note/src/main/ets/ui/components/MathEditorOverlay.ets`
  - 新增 `photoImportLeaseActive` 属性。
  - 文本输入与取消按钮绑定共享租约；Done 启用函数同步纳入租约。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
  - Math 层传入 `this.photoImportBusy`。
  - `onDraftChange/onCancel/onConfirm` 先拒绝共享导入租约，再拒绝历史租约。
- `note/src/test/MathEditorOverlay.test.ets`
  - 模型 fixture 覆盖共享租约下 Done 禁用（未运行 Hypium）。

## 静态验证

- 新增焦点 Replay：
  `docs/migration/replays/d02-open-math-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=10 FAILED=0`。
- 相邻本地 LaTeX 编辑 Replay 同步后通过，原四态模型 Replay 输出 `TOTAL=30 FAILED=0`。
- ArkTS 检查 `MathEditorOverlay.ets` 无诊断；`NoteCanvasView.ets` 仅保留既有
  unused/deprecation 信息。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。
