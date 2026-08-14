# ADR-0187：资产临时工件的启动期回收边界

## 状态

Accepted，2026-08-14。

## 问题

Phase 207 把待删除的规范资产先原子改名到 `assets/trash`，避免较早的异步 unlink
误删后来重新发布的同 hash 文件；图片与录音发布也先写入 `assets/pending`，完成校验和
`fsync` 后才改名到 `assets/final`。正常异常路径会删除临时文件，但进程在以下窗口退出时仍会留下
孤儿：

- 图片或录音尚未从 `assets/pending` 发布到 `assets/final`；
- 规范资产已经 detach 到 `assets/trash`，但尚未完成 unlink。

系统 Backup 正确排除了这两个目录，因此这些文件既不会恢复为可用资产，也没有后续消费者；如果不在
后续启动回收，只会持续占用应用私有存储。

## 原版证据

- `decompiled_1.0.3/sources/defpackage/gv2.java` case 13：相关管理器启动时遍历
  `temp_recordings` 与 `AudioCaptures` 并删除上次运行遗留的捕获文件。
- 同文件 case 2：管理器启动时删除 cache 中 `temp_*` 和 `*_converted.pdf` 临时工件。
- `defpackage/p29.java` 在资产管理器构造时启动专用协程；`defpackage/zq6.java` 则把已发布资产放在
  私有 `assets/final` 规范目录。

这些证据建立的是生命周期语义：已中断的私有临时工件在拥有者下一次启动时回收；它不授权扫描或删除
规范资产，也不要求 Harmony 逐目录复刻 Android 的文件布局。

## 决策

1. `DatabaseManager` 第一次 `openAndMigrate()` 在发布 `RdbStore` 前调用
   `cleanupInterruptedAssetArtifacts()`。此时任何依赖 `getStore()` 的进程内资产写者尚不能运行，因而
   不会与当前进程的图片、录音发布或删除流程重叠。
2. 只扫描 `<filesDir>/assets/pending` 与 `<filesDir>/assets/trash` 的直接子项，不递归进入目录。
3. 只删除普通文件，并严格接受 Harmony 自己生成的三种名称：
   - `pending_asset_<time>_<random>.tmp`
   - `pending_recording_<time>_<random>.tmp`
   - `deleted_asset_<time>_<random>_<attempt>.tmp`
4. `listFileSync()` 返回的路径必须重新证明是目标目录的直接子项；嵌套路径、目录穿越、未知名称、目录和
   目录外目标全部保留。
5. 单文件失败只记录并继续后续文件；目录不存在视为正常。目录类型错误、枚举失败或 unlink 失败会计入
   失败报告和日志，但不阻断数据库启动。下次初始化仍可幂等重试残留文件。
6. `assets/final` 不在清理范围内。数据库提交后、detach 前崩溃形成的规范孤儿仍可被同 hash 到达路径
   逐字节校验和复用，不能在没有完整数据库所有权证明时猜测删除。
7. 系统 Backup 继续排除 `assets/pending` 与 `assets/trash`，避免把瞬态工件重新带入恢复集。

## 结果

- detach 后崩溃不再永久积累 `assets/trash` 文件。
- 图片/录音写入中断不再永久积累 `assets/pending` 文件。
- 清理不能触及规范资产、未知应用文件或嵌套目录，路径所有权边界保持 fail closed。
- 数据库初始化不会因为一个不可删除的垃圾文件而完全不可用，同时精确失败计数仍可用于设备诊断。

## 边界

- 当前门禁证明进程内首次初始化顺序；真实权限失败、磁盘故障、进程杀死和可能的跨进程文件访问仍需
  设备故障注入。
- 不清理未知旧版本命名，除非后续能从原版或已发布 Harmony 版本取得确定的生产者证据。
- 不处理无数据库行的 `assets/final` 规范孤儿；该问题需要独立的引用扫描、内容哈希复核和并发协议。
