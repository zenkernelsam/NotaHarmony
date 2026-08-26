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

## Phase 522 增量（2026-08-26）

- 复核发现 Math 覆层取消与完成直接回调只拒绝共享导入租约；`busy=true` 时晚到点击仍进入组件回调，
  再依赖父级 `historyBusy` 与方法内部守卫兜底。
- 两个按钮回调统一先拒绝 `busy || photoImportLeaseActive`；输入 onChange 的共享租约检查、Done
  模型门禁、父级历史串行化和正常编辑语义不变。
- 共享租约 Replay 扩展至 `TOTAL=15 FAILED=0`，锁定恰好两处组合早退并禁止旧的“仅租约”点击模式。
- 验证补录：全量 Desktop Replay `421/421`（32.518 秒）；clean 3.014 秒、ohosTest HAP 8.832 秒、default HAP 27.966 秒均静态构建成功。
- ArkTS 检查 `MathEditorOverlay.ets` 无诊断；`NoteCanvasView.ets` 仅既有 unused/deprecation 提示。
