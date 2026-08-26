# Harmony Evidence — 画布插入信号共享照片导入租约

日期：2026-08-26
阶段：Phase 480
结论：通过（静态验证）

## 代码证据

- `NoteCanvasView.ets`
  - `onMathInsertSignalChange` 先拒绝 `photoImportBusy`，再调用 `startMathInsert()`。
  - `onPhotoInsertSignalChange` 先拒绝同一租约，再调用 `startOriginalPhotoInsert()`。
  - Math 插入内部继续按原顺序检查共享导入、历史忙、页面健康和身份；照片插入继续由
    `canStartOriginalPhotoInsert()` 拒绝历史与共享导入。
- 新增专项 Replay 锁定两处回调守卫和两条内部防线。

## 静态验证

- ArkTS：`note/src/main/ets/ui/editor/NoteCanvasView.ets` 无错误；仅既有未使用符号警告和
  弃用 API 信息级提示。
- 聚焦 Replay：
  `docs/migration/replays/d02-canvas-signals-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=4 FAILED=0`。
- 相邻 Replay：已打开数学编辑共享租约 10/10、照片导入页面操作租约 12/12 通过。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （31.856 秒）。
- clean：3.246 秒；ohosTest HAP：9.781 秒；default HAP：30.456 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
