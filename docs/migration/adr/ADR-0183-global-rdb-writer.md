# ADR-0183：单例 RdbStore 的全局写者与领域锁顺序

## 决策

新增模块级 `databaseWriteMutex`，作为 `DatabaseManager` 发布的单例 `RdbStore` 的进程内唯一运行期写者。原有 `editorPersistenceMutex` 与 `libraryMetadataMutationMutex` 保留名称以兼容调用方，但都改为同一 `databaseWriteMutex` 的别名，不再各自创建 `AsyncMutex`。

所有已经开始事务的编辑器快照、页面结构、持久 Undo/Redo、同步 inbox、录音、笔记和文件夹仓储因此进入同一 FIFO 写队列。直接拥有文件生命周期的资产链路仍使用独立 `assetMutationMutex`；锁序固定为：

`assetMutationMutex -> databaseWriteMutex`

`AssetRepositoryImpl` 与图片资产到达在取得资产锁后再取得数据库写者。录音创建和笔记删除原有的 `asset -> editor/library` 顺序在别名化后自动等价于 `asset -> database`。数据库写者不得反向取得资产锁。

单语句写入也遵守同一写者：`ToolRepositoryImpl` 删除私有 `writeMutex`，四个工具/工具箱保存入口改用 `databaseWriteMutex`；`NoteRepositoryImpl.saveViewState()` 的 `ON_CONFLICT_REPLACE` 同样进入全局写队列。

ADR-0184 补正资产删除边界：`OriginalAssetReferenceStore` 和 `OriginalCreateBlockOperation` 等事务内 helper 也会写 `note_asset`，但它们依赖数据库写者而不直接取得资产锁。资产或笔记删除因此不能在释放数据库写者后继续对旧规范路径执行 unlink。删除事务提交后、仍持有数据库写者时先把文件原子改名到唯一隔离路径；随后释放数据库写者，在资产锁内删除隔离文件。数据库写者只覆盖快速 rename，不覆盖最佳努力 unlink。

`DatabaseManager.openAndMigrate()` 的初始化事务不取得运行期写者。该方法由单例 `initPromise` 串行，且只在全部 DDL、迁移、回填和外键验证完成后才执行 `this.rdbStore = store`；未发布的 store 不可能与仓储运行期写入交叠。

## 原因

此前存在至少四个互不相识的写域：

- `editorPersistenceMutex`：页面、元素快照、op、同步 inbox 和持久历史；
- `libraryMetadataMutationMutex`：笔记/文件夹元数据；
- `assetMutationMutex`：资产引用和到达；
- `ToolRepositoryImpl.writeMutex`：工具状态。

它们最终都对同一个 `DatabaseManager.getStore()` 返回值调用 `beginTransaction()` 或执行写语句。领域锁只能防止同类入口互撞，不能防止页面保存与文件夹移动、同步 reducer 与标题保存、资产到达与页面/笔记删除、工具状态保存与任意在途事务发生跨域交叠。即使字段级补丁避免了旧整行覆盖，第二个 `beginTransaction()` 仍可能撞上第一个事务；单语句写入也不应在另一个子系统的事务边界内执行。

Harmony 当前把原版多个 Room 表域适配进一个 `nota.db`/`RdbStore`。因此不能机械照搬“每个仓储一把锁”，而应在合并后的存储边界恢复单写者语义。

## 原版证据

Android 1.0.3 的 Room 基础类 `decompiled_1.0.3/sources/defpackage/x5c.java` 持有 `internalTransactionExecutor` 字段 `d`。`defpackage/t5c.java:295-310` 用 `new cyc(tu2Var.i, 1)` 构造该事务执行器，并把事务 coroutine context 绑定到它。

`defpackage/cyc.java` 使用 `ArrayDeque` 保存 Runnable；`execute()` 只在当前任务为空时启动队首任务，每个包装任务完成后才调用 `a()` 取下一项。因此同一个 RoomDatabase 的事务不是由每个 DAO 自己并发进入，而是通过数据库级串行执行器排队。

原版的 NoteAsset、ClientOp、资料库元数据、搜索和工具状态可能位于不同 RoomDatabase；Harmony 将这些适配表放进同一个 store 后，共享写者是对原版数据库级事务执行语义的必要收敛，而不是声称原版全应用只有一把全局锁。

## 验收约束

- `DatabaseWriteMutex.ets` 是唯一新建运行期 RDB 写互斥的模块。
- `EditorPersistenceMutex.ets`、`LibraryMetadataMutationMutex.ets` 只能导出该对象的兼容别名。
- 除尚未发布 store 的 `DatabaseManager` 初始化外，含 `beginTransaction()` 的运行期 data 文件必须能到达 `databaseWriteMutex` 或其别名。
- 资产、录音和笔记删除的锁序必须始终是资产锁在前、数据库写者在后。
- 删除已提交资产时，规范路径必须在数据库写者释放前完成隔离；慢速 unlink、通知和其他提交后副作用不得无故延长数据库写者持有时间。
- 新增独立 RDB 写锁或新的事务入口时，`d02-global-rdb-writer.mjs` 必须失败，直到调用链被纳入或有 ADR 说明例外。

## 边界

该互斥只在当前应用进程内生效，不替代 SQLite 自身锁、跨进程协调或设备故障恢复。只读查询仍依赖 RdbStore/SQLite 的读一致性；本阶段没有把所有读取串行化，也没有更改原有事务内容、补偿策略或数据库模式。

全局写者会让长事务阻塞其他保存，因此后续仍应审计事务内文件 I/O、过大批次和可移到提交后的工作。图片资产到达目前为了文件/行补偿仍在事务内完成原子文件落位；资产删除只在写者内执行规范路径到隔离路径的原子 rename，实际 unlink 留在写者外。这些都是一致性边界，不代表任意文件 I/O 都应留在写锁内。真实后台同步、快速翻页、录音到达和应用生命周期仍需设备并发测试。
