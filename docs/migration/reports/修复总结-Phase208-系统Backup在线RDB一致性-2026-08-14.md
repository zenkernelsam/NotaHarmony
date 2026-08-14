# Phase 208 修复总结：系统 Backup 在线 RDB 一致性

## 发现

Phase 207 完成资产删除规范路径隔离后复核系统 Backup，确认原实现仍把活跃
`filesDir`/`databaseDir` 顺序复制到快照：

1. SQLite 主库、WAL 与 SHM 可以来自不同瞬间，文件复制成功不等于得到可恢复数据库。
2. 数据库和 `assets/final` 可能跨越一次资产事务；尤其录音资产会先准备 canonical 文件，再取得共享数据库写者提交 operation 与引用。
3. `assets/pending`、Phase 207 的 `assets/trash` 与可再生 `glmath` 被误当成耐久数据。
4. schema 1 的文件级恢复没有数据库 rollback；新恢复若数据库 restore 或文件补偿失败，会丢失共同恢复边界。
5. 继续审阅时还发现：成功后清扫 rollback 目录若半途失败，旧结构会错误进入已经失去部分副本的补偿；补偿本身失败后又会删除最后的文件/数据库恢复工件。

## 修复

- manifest 升级到 schema 2，同时保留 schema 1 读取与旧文件级恢复分支。
- 备份/恢复按 `assetMutationMutex -> databaseWriteMutex` 取得一致性锁；仍保留前后两次数据库快照比较，用于发现不受本进程 mutex 约束的数据库变化。
- 使用 `RdbStore.backup()` 生成在线 `nota.db` 快照，不再递归复制活跃 `databaseDir` 或 WAL/SHM；schema 2 只接受最多一个、大小为正的 `databaseDir/nota.db` 条目。
- 第一份 RDB 快照先生成，再复制耐久 `filesDir`，随后生成第二份 RDB 快照并逐字节比较；不同则整次 staging 失败，不发布新 snapshot。
- 排除 `assets/pending`、`assets/trash`、`glmath`，并在 schema 2 manifest 恢复校验中拒绝这些条目；`assets/final` 仍是耐久对象。
- 所有复制都校验源大小、目标大小及逐字节相等；修复双文件比较中“第二个 open 失败会泄漏第一个句柄”的问题。
- schema 2 恢复先复制并校验数据库源，再备份当前数据库为 rollback；普通文件替换成功后才调用 `RdbStore.restore()`。
- 数据库恢复失败时先尝试数据库补偿，再逆序补偿文件；文件 rollback 现在返回完整性，缺失源、目录冲突或 rename 失败不会被误报为成功。
- 不完整文件补偿保留 rollback 目录；数据库补偿失败保留 rollback DB。新的 backup/restore 在这些恢复现场存在时 fail closed，不会静默覆盖。
- 成功后的 rollback 清扫移出应用失败边界并改为 best-effort，避免“清扫半途失败后再尝试已不可能完整的补偿”。
- `onRelease()` 与其他 Ability 操作串行，关闭并清空缓存的 `RdbStore`。

## 原版对照

- `decompiled_1.0.3/sources/defpackage/x5c.java`：Room 明确拒绝跨 suspending transaction coroutine context 访问数据库。
- `defpackage/t5c.java`：Room 配置 query/transaction executor。
- `defpackage/cyc.java`：受同步保护的队列一次调度一个任务，体现原版数据库工作的串行边界。
- 原版资产到达使用 pending -> canonical 生命周期；`ExportSweepWorker.java` 与 `g64.java` 单独管理临时导出清扫。

Harmony 采用 `RdbStore.backup/restore`、双快照门禁和现有资产/数据库锁恢复同一一致性目标；不声称原版 Android 使用相同 API 或目录布局。决策记录见
`ADR-0185-system-backup-online-rdb-consistency.md`。

## Replay

- 更新：
  - `d02-system-backup-bundle-version-identity.mjs`
  - `d02-system-backup-restore-file-rollback.mjs`
  - `d02-arkts-build-contracts.mjs`
- 新增：
  - `d02-system-backup-rdb-snapshot-consistency.mjs`
  - `d02-system-backup-rdb-restore-rollback.mjs`
  - `d02-system-backup-transient-root-exclusions.mjs`
- 全部 12 个 `d02-system-backup*.mjs`：`ASSERTIONS=98 FAILED_FILES=0`。
- ArkTS 合约、文本精确字节、全局 RDB 写者、资产删除隔离/引用门禁、图片/录音资产到达、WebDAV 批次补偿与资料库提交边界等 10 组相关 replay：全部退出码 0。

## 构建与检查

- `note@default assembleHap`：`BUILD SUCCESSFUL`；`CompileArkTS`、`PackageHap` 通过。
- `note@ohosTest assembleHap`：`BUILD SUCCESSFUL`；`OhosTestCompileArkTS`、`PackageHap` 通过。
- `git diff --check`：通过。
- 未启动设备、模拟器或虚拟机。

## 全量 replay 观察

额外执行 195 个桌面 replay：169 个通过，26 个失败。26 个失败文件全部仍硬编码
`DB_VERSION: number = 61`，而已提交的 Phase 207 数据库迁移已升级到 v62；逐文件检索确认这 26 个脚本都包含同一过期断言。它们不是 Phase 208 代码回归，已列为下一阶段的 replay 版本门禁去脆弱化工作，不能通过回退生产数据库版本来“修绿”。

## 仍需设备验证

- `RdbStore.backup/restore` 在真实系统 BackupExtension 进程、WAL 高并发、磁盘满、权限异常与进程终止下的行为。
- 前后在线快照在真实设备 SQLite 实现中，对无写入数据库是否稳定逐字节一致。
- 数据库 restore 失败后再次 restore rollback 的真实原子性，以及系统对失败后 `backupDir` rollback 目录的保留周期。
- 保留恢复工件后的用户可见诊断/导出/自动修复入口尚未实现；当前策略是 fail closed 并记录精确路径。
