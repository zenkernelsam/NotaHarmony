# Phase 170 修复总结：备份发布 Manifest 预校验

## 发现

`BackupBatchPublisher` 原先只执行对象上传和 hash 校验，未在上传前校验 `batchId`、时间、noteId、revision、updatedAt 等 manifest 必需字段，可能发布自身无法解析的备份。

## 修改

- `note/src/main/ets/data/BackupBatchPublisher.ets`
- 新增 `ADR-0147-backup-publisher-manifest-prevalidation.md`
- 新增 `d02-backup-publisher-manifest-prevalidation.mjs`

发布前现在复用 `isValidBackupBatchId`，并检查批次时间、源笔记身份、更新时间、revision 和非空数据；非法输入不会创建远端目录或孤立对象。

## 验证

- Replay：`TOTAL=5 FAILED=0`
- `note@default assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- `note@ohosTest assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- 未启动设备、模拟器、虚拟机或 Hypium。

## 未闭环

多笔记恢复跨单篇导入的数据库事务和真实 WebDAV 端到端故障注入仍需后续阶段。
