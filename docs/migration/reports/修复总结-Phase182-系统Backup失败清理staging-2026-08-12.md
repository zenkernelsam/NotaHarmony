# Phase 182 修复总结：系统 Backup 失败清理 staging

## 发现

系统 Backup 在文件收集、复制或 manifest 写入失败时，原实现会留下未发布的
`nota-snapshot.staging`，并且进度状态仍可能停留在 collecting/restoring 之前的阶段。

## 修改

- `note/src/main/ets/notebackupability/NoteBackupAbility.ets`
- 新增 `ADR-0159-system-backup-staging-cleanup-on-failure.md`
- 新增 `d02-system-backup-staging-cleanup.mjs`

`createSnapshot()` 现在由统一失败门包围：失败时尽力删除 staging、设置 `phase=failed`
和错误文本，再重新抛出原异常；已发布快照和 previous 回滚路径保持不变。

## 验证

- Replay：`TOTAL=5 FAILED=0`
- HAP 构建：本轮未执行，仓库根目录无 `hvigorw`/`hvigorw.bat`
- 未启动设备、模拟器、虚拟机或 Hypium

## 未闭环

真实 CoreFileKit 文件系统故障、进程中断期间的 staging 残留仍需设备 fault injection。
