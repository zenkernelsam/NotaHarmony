# Phase 176 修复总结：备份 Manifest 时间戳完整性

## 发现

备份 manifest 的 `createdAt` 与条目 `updatedAt` 原先只检查 `Number.isFinite`，小数和超出安全整数范围的值仍可进入批次选择、revision 对齐和恢复提示。

## 修改

- `note/src/main/ets/data/BackupBatchSpec.ets`
- `note/src/main/ets/data/BackupBatchPublisher.ets`
- 新增 `ADR-0153-backup-manifest-timestamp-integrity.md`
- 新增 `d02-backup-manifest-timestamp-integrity.mjs`

解析和发布边界现在统一要求正安全整数，正常 `Date.now()` 值不受影响。

## 验证

- Replay：`TOTAL=5 FAILED=0`
- Phase175 唯一性回归：`TOTAL=5 FAILED=0`
- `note@default assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- `note@ohosTest assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- 未启动设备、模拟器、虚拟机或 Hypium。

## 未闭环

真实 WebDAV 时间排序与时钟异常仍需 BackupBatch 套件验证。
