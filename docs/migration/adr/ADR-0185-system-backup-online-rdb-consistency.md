# ADR-0185：系统 Backup 在线 RDB 一致性与恢复补偿

## 状态

Accepted，2026-08-14。

## 问题

旧版 `NoteBackupAbility` 递归复制活跃 `filesDir` 与 `databaseDir`。这对 SQLite/WAL 不成立：

- `nota.db`、`nota.db-wal` 与 `nota.db-shm` 可能来自不同写入瞬间，文件都能复制完成也不代表数据库可恢复。
- 数据库快照与 `assets/final` 可能跨越一次资产提交，恢复后会出现数据库引用与文件集合不匹配。
- `assets/pending`、`assets/trash` 是提交前/删除后的临时生命周期，`glmath` 可由 rawfile 重新生成，不应成为耐久备份对象。
- 直接覆盖数据库后再遇到文件复制失败，没有数据库级补偿路径。

## 原版依据

- 原版 1.0.3 `defpackage/x5c.java` 对 Room 事务的 coroutine context 有明确约束，拒绝从继承的事务切换到不同上下文访问数据库。
- `defpackage/t5c.java` 为 Room 配置 query/transaction executor；`defpackage/cyc.java` 通过受同步保护的队列一次只调度一个 Runnable。原版的耐久状态不是靠并发复制活跃 SQLite 文件得到的。
- 原版资产到达先进入 pending，再在资产互斥边界内发布 canonical 文件；导出临时文件由
  `ExportSweepWorker`/`g64.java` 管理和清扫。临时工作区与正式耐久对象具有不同生命周期。

这些证据约束的是一致性和生命周期，不声称原版 Android 使用了 Harmony 的
`RdbStore.backup/restore` 或相同目录名。

## 决策

1. 新快照 manifest 升级为 schema 2；schema 1 继续保留旧文件级恢复兼容。
2. 同一进程内按现有全局顺序取得 `assetMutationMutex`，再取得 `databaseWriteMutex`，覆盖数据库快照、耐久文件复制和恢复应用窗口。
3. 不再递归复制活跃 `databaseDir`。若 `nota.db` 存在，使用 `RdbStore.backup()` 生成第一份在线快照，manifest 中只发布为 `databaseDir/nota.db`。
4. 耐久文件复制完成后再生成第二份在线数据库快照，并逐字节比较。两份不一致时整次备份失败，不发布 staging。双快照门禁也用于发现不受本进程 mutex 约束的数据库写入。
5. `filesDir` 收集和 schema 2 恢复都排除/拒绝 `assets/pending`、`assets/trash` 与 `glmath`。源和目标复制后做大小及逐字节核验。
6. schema 2 恢复先把备份数据库复制到私有临时名，再用 `RdbStore.backup()` 保存当前数据库作为 rollback；随后替换普通文件，最后调用 `RdbStore.restore()`。
7. 恢复失败且数据库 restore 已开始时，先恢复 rollback 数据库，再逆序恢复已替换文件。schema 1 仍使用原有文件级回滚。
8. 文件回滚逐项报告完整性；缺失 rollback 源、目录冲突或 rename 失败时保留 rollback 目录。数据库补偿失败时保留数据库 rollback 快照。后续 backup/restore 会拒绝覆盖未处理的恢复现场。
9. 成功后的 rollback 目录清扫位于应用失败边界之外，清扫失败只留下可诊断残留，不会在已开始删除回滚副本后反向触发不完整补偿。
10. 普通 RDB 临时文件在 `finally` 中清除；Ability release 与其他操作串行，并关闭缓存的 `RdbStore`。

## 结果

- 新备份不再包含活跃 WAL 组合，也不会把删除隔离区、pending 半成品或可再生公式资源当成用户数据。
- 同进程资产发布与数据库写入在备份/恢复期间被一致性锁阻挡；进程外数据库变化会被前后快照比较拒绝。
- schema 2 的数据库与文件恢复拥有共同失败边界，同时不丢弃既有 schema 1 备份。
- 补偿本身失败时不再删除最后的恢复副本，也不会允许下一次操作静默覆盖事故现场。

## 边界

- mutex 是进程内约束；双数据库快照只能探测数据库变化，不能证明任意外部进程的“只写文件、不写数据库”行为。当前耐久 `assets/final` 写者均使用资产锁与共享数据库写者。
- schema 1 兼容分支仍需直接恢复旧 `databaseDir` 条目，无法反向赋予旧快照在线 RDB 一致性。
- 保留的恢复工件目前只提供 fail-closed 保护和日志路径，尚未提供设置页中的自动修复/导出 UI；需要设备故障注入确认系统对 `backupDir` 的失败后保留周期。
- `RdbStore.backup/restore` 的真实设备路径、进程调度、断电与磁盘故障行为仍需设备故障注入验证；本阶段不启动模拟器或虚拟机。
