# ADR-0190：Note 导出临时工件的启动期回收

## 状态

Accepted，2026-08-14。

## 问题

`NoteExporter.exportToFile()` 先把完整 `.note` 包写到应用私有 `context.tempDir`：

```text
export_<time>.note
```

随后系统 picker 返回目标 URI，导出器再把该文件复制到用户选择的位置。正常成功、取消和异常路径都会在
`finally` 中关闭句柄并删除临时文件；但如果应用在写完临时包后、picker 交互期间或目标复制期间被杀死，
进程内 `finally` 无法执行。该临时包没有恢复协议或后续消费者，会长期占用私有空间，并保留一份完整的
用户笔记副本。

Phase 211 已为录音捕获文件建立独立启动清理，但其 ADR 明确不授权删除 `.note` 导出文件。录音与导出具有
不同生产者、名称和消费条件，不能靠扩宽录音正则或清空整个 `tempDir` 处理。

## 原版证据

- `decompiled_1.0.3/sources/defpackage/g64.java`：原版导出仓库拥有私有
  `cacheDir/exports` 目录，记录活动目录并按 `.created` 时间调度 `ExportSweepWorker`；过期目录会被递归回收，
  总体缓存还受 500 MiB 上限约束。
- `decompiled_1.0.3/sources/defpackage/f64.java`：创建随机导出目录及 `.created` 标记，并维护进程内活动集合。
- `decompiled_1.0.3/sources/com/gingerlabs/notability/data/library/state/ExportSweepWorker.java`：后台 worker
  调用导出仓库清扫逻辑。
- `decompiled_1.0.3/sources/defpackage/gv2.java` case 2：相关拥有者启动时还会删除 cache 中遗留的
  `temp_*` 与 `*_converted.pdf` 工件。

原版实现证明：私有导出/cache 工件由明确拥有者管理，进程中断后必须有后续清扫。Harmony 当前
`export_<time>.note` 不是可复用的分享缓存；目标 URI 没有持久恢复记录，原进程死亡后继续保留它没有功能价值，
因此下一次安全启动边界即可回收，无需复制原版 24 小时共享导出目录策略。

## 决策

1. 新增 `cleanupInterruptedNoteExports(tempRoot)`，在第一次
   `DatabaseManager.openAndMigrate()` 发布 `RdbStore` 前扫描 `context.tempDir`。
2. `BackupPage` 只有数据库初始化完成后才能创建 `NoteExporter`；同一进程后续 `initialize()` 会复用已发布
   store，不会重复扫描。因此清理发生在当前进程任何可发起的导出之前，不会删除活动导出。
3. 只接受当前生产者的严格名称 `export_<digits>.note`。不删除其他 `.note`、平台临时文件、未知旧版命名或
   未来命名。
4. 只枚举 `tempDir` 直接子项，不递归进入目录，也不执行目录删除。枚举结果必须重新证明是目标目录的直接
   子路径；嵌套路径、目录穿越、目录外目标和空路径全部 fail closed。
5. 名称匹配仍必须是普通文件才可 `unlinkSync()`；同名目录会保留。
6. 单文件删除失败只计数、记录并继续；根路径为空、根不是目录、枚举失败或单项失败均不阻断数据库启动，
   后续进程启动可再次幂等重试。
7. 保留 `NoteExporter` 正常路径的句柄关闭、`fsync` 与 `finally` 删除。启动回收只覆盖进程死亡窗口，不改变
   picker 或用户目标文件语义。
8. 系统 Backup 继续只快照 `filesDir` 与 `databaseDir`，不把 `tempDir` 临时包带入恢复集。

## 结果

- 导出或 picker 期间杀进程不再永久积累完整 `.note` 临时副本。
- 录音清理与导出清理保持独立所有权，任何一方都不能误删另一方文件。
- 未知文件、普通用户 `.note`、嵌套文件和名称伪装目录全部保留。
- 单个不可删除工件不会使数据库和应用启动整体失败，并保留可诊断统计。

## 边界

- 桌面 replay 验证原版证据、生产者命名、启动顺序、路径门禁、删除/保留集合与幂等性；真实进程杀死、
  权限拒绝、文件占用和存储故障仍需设备故障注入。
- 当前只回收仓库中已证实的 `export_<digits>.note`。若以后改变生产者命名，必须同步扩展并验证清理协议，
  不能改成宽泛的 `.note` 后缀删除。
- 本决策不实现原版共享导出目录的 24 小时复用、500 MiB 容量管理或 WorkManager 调度；Harmony 当前没有
  对应的可恢复分享缓存，因此这些机制不属于本缺口所需范围。
