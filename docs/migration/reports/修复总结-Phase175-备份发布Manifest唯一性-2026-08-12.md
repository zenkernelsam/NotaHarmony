# Phase 175 修复总结：备份发布 Manifest 唯一性

## 发现

`BackupBatchSpec.parseBackupBatch()` 拒绝重复 noteId 和重复文件名，但 `BackupBatchPublisher` 上传前没有执行这两个约束。重复输入会先写入远端对象，之后发布一个恢复器无法接受的 manifest，形成孤儿批次。

## 修改

- `note/src/main/ets/data/BackupBatchPublisher.ets`
- 新增 `ADR-0152-backup-publisher-manifest-uniqueness.md`
- 新增 `d02-backup-publisher-manifest-uniqueness.mjs`

发布器现在在 `ensureBackupDir()` 前建立 noteId/fileName 集合；重复项立即返回 OBJECT_UPLOAD 失败，远端不会发生本批次写入。

## 验证

- Replay：`TOTAL=5 FAILED=0`
- `note@default assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- `note@ohosTest assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- 未启动设备、模拟器、虚拟机或 Hypium。

## 未闭环

真实 WebDAV 服务上的重复输入 fault injection 仍需 BackupBatch 套件执行。
