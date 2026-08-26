# Harmony Evidence — 工具栏按钮禁用与回调租约一致化

日期：2026-08-26
阶段：Phase 474
结论：通过（静态验证）

## 代码证据

- `EditorToolbar.ets`
  - Photo 与 Math 按钮在 `toolStateLoading` 外叠加共享照片导入租约禁用。
  - Undo / Redo 在既有能力状态外叠加同一租约禁用。
  - `NotePage` 回调先拒绝该租约，再保留页面操作和历史等待防御；`NoteCanvasView`
    内部历史路径继续按原顺序拒绝导入与历史忙状态。
- 新增专项 Replay 锁定四处按钮一致性绑定。

## 静态验证

- ArkTS：`note/src/main/ets/ui/editor/EditorToolbar.ets` 无诊断。
- 聚焦 Replay：
  `docs/migration/replays/d02-toolbar-button-consistency-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=4 FAILED=0`。
- 相邻 Replay：工具栏直改 11/11、历史工具栏 10/10、面板开关 6/6、顶栏直改 5/5 全部通过。
- 全量 Desktop Replay：`REPLAY_FILES=415 PASSED=415 FAILED_FILES=0`
  （30.648 秒）。
- clean：3.228 秒；ohosTest HAP：9.918 秒；default HAP：34.423 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
