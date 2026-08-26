# Harmony Evidence — 紧凑插入菜单共享照片导入租约

日期：2026-08-26
阶段：Phase 481
结论：通过（静态验证）

## 代码证据

- `EditorToolbar.ets`
  - `buildCompactToolMenu()` 中 `insert_photo` 与 `insert_math` action 先拒绝
    `photoImportLeaseActive`，再分别调用 `onInsertPhotos()` / `onInsertMath()`。
  - 同菜单四项工具直改、既有 Builder 启用条件、回调守卫和选区样式路径不变。
- 新增专项断言扩展既有 Phase 479 Replay，锁定两项 action 的第一层防线。

## 静态验证

- 聚焦 Replay：
  `docs/migration/replays/d02-toolbar-builders-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=4 FAILED=0`。
- ArkTS：`note/src/main/ets/ui/editor/EditorToolbar.ets` 无诊断。
- 相邻 Replay：工具栏直改 11/11、按钮一致化 4/4 通过。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （34.952 秒）。clean：3.507 秒；ohosTest HAP：10.803 秒；default HAP：33.518 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
