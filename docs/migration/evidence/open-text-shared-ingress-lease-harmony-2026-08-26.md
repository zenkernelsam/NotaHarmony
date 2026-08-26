# Harmony 证据 — Phase 469 已打开文本共享租约修复

## 变更位置

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
  - 新增 `photoImportLeaseActive` 属性。
  - TextArea、Done 与 Cancel 在共享导入期禁用。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
  - 将 `photoImportBusy` 传给已打开文本层。
  - `onDraftChange` 与 `onCancel` 先拒绝共享导入租约，再拒绝历史租约。

## 静态验证

- 新增焦点 Replay：
  `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=9 FAILED=0`。
- 相邻 resize/edit、空白终提交、文本取消/完成共享租约与 stale final commit Replay 通过。
- ArkTS 检查 `TextBlockOverlay.ets` 与 `NoteCanvasView.ets` 无错误；仅既有信息级提示。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。

---

## Phase 483 增量验证（2026-08-26）

- `NoteCanvasView.beginTextEditingAt()` 新增首行门禁，先拒绝共享照片导入租约和历史租约，
  再执行原有文本块命中与编辑状态切换。
- 既有专项 Replay 扩展断言，当前输出 `TOTAL=10 FAILED=0`。
- ArkTS 目标无错误，仅既有警告与信息级提示；相邻文本提交与文本取消 Replay 通过。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （35.273 秒）。clean：7.602 秒；ohosTest HAP：13.184 秒；default HAP：34.080 秒。

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
