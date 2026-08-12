# Phase 184 修复总结：系统 Backup Ability 串行操作

## 发现

四个 Backup Ability 入口可以并发执行，而它们共享 snapshot、previous、staging 和
restore rollback 路径。并发 backup/restore 会产生交叉文件操作和错误进度状态。

## 修改

- `note/src/main/ets/notebackupability/NoteBackupAbility.ets`
- 新增 `ADR-0161-system-backup-ability-serial-operations.md`
- 新增 `d02-system-backup-ability-serial-operations.mjs`

所有入口现在通过 Ability 内部 promise 队列串行执行；失败请求会 settled，但不会阻塞
后续请求。

## 验证

- Replay：`TOTAL=7 FAILED=0`
- HAP 构建：本轮未执行，仓库根目录无 `hvigorw`/`hvigorw.bat`
- 未启动设备、模拟器、虚拟机或 Hypium

## 未闭环

系统终止进程导致的跨实例恢复仍需 CoreFileKit 真机 fault injection。
