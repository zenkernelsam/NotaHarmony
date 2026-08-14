# ADR-0184：资产删除的规范路径隔离边界

## 决策

删除 `note_asset` 最后引用或显式删除无引用资产时，数据库事务提交后不得直接释放全局数据库写者并保留规范文件路径等待稍后 unlink。删除目标行后、提交事务前，必须按 `local_path` 查询剩余 `note_asset` 行；只有没有其他行继续拥有同一路径时，才允许把它列入隔离集合。仍持有 `databaseWriteMutex` 时，先把该文件从规范路径原子改名到应用私有的唯一隔离路径：

`<filesDir>/assets/trash/deleted_asset_<unique>.tmp`

改名成功后才释放数据库写者；实际 unlink 在数据库写者之外、但仍在 `assetMutationMutex` 内最佳努力执行。改名失败或源文件不存在时不安排稍后的规范路径删除，宁可留下可复用孤儿文件，也不能冒险删除后续写者重新发布的文件。

`AssetRepositoryImpl.deleteAsset()` 与 `NoteRepositoryImpl.deleteNote()` 共用 `detachAssetFileForDeletion()`。隔离和删除都必须通过应用 files 根目录校验，拒绝越界路径与父目录穿越。

## 原因

Phase 206 将所有运行期 RDB 写入收敛到同一个数据库写者后，继续补审发现此前“事务提交后释放数据库写者、只持有资产锁再 unlink”仍有竞态。`OriginalAssetReferenceStore.mergeOriginalAssetReference()`、`OriginalCreateBlockOperation` 等 reducer helper 会在编辑器或同步事务中直接插入/更新 `note_asset`；它们共享数据库写者，但并不全部取得 `assetMutationMutex`。

旧顺序可能发生：

1. 删除方持有 `assetMutationMutex -> databaseWriteMutex`，删除无引用资产行并提交；
2. 删除方释放数据库写者，但仍准备对规范 hash 路径执行 unlink；
3. 编辑器或同步事务取得数据库写者，为同一内容 hash 新增引用或重新发布资产行；
4. 旧删除方 unlink 规范路径，新引用立即变成缺文件状态。

仅把 unlink 放回全局写者可以消除竞态，但会让潜在慢速文件删除阻塞所有页面、同步、工具和资料库写入。原子 rename 只占用很短的数据库临界区，并把旧清理目标换成永不被新引用使用的唯一路径；随后慢速 unlink 不再威胁新规范文件。

补审 canonical/legacy hash 迁移又发现第二个所有权边界：`OriginalAssetReferenceStore` 与 `OriginalCreateBlockOperation` 会在 canonical 行和 legacy 行之间保留首选 `local_path`，过渡数据可能让两个资产行暂时指向同一文件。只按待删行的 `asset_hash` 判断会把仍由另一行使用的文件误当成独占文件。因此路径门禁必须在目标行删除后、同一事务内查询完整 `note_asset.local_path` 所有者；笔记删除还需先收集并去重候选路径，再判断全部剩余行。

## 原版证据

- `decompiled_1.0.3/sources/defpackage/zq6.java:152-160`：原版资产位于私有 `assets/final`，文件名由完整 `AssetHash` 派生，是内容寻址的规范路径。
- `defpackage/p29.java:26,42-60`：原版资产管理器持有专用 `em8` mutex。
- `defpackage/em8.java`：该对象是 coroutine mutex；`a()` 取得、`b()` 释放。
- `defpackage/mr1.java` 与 `defpackage/vs8.java`：收到资产后在该 mutex 内核对 hash，并替换 `zq6.h(...)` 指向的规范文件。

原版证据证明规范 hash 文件的发布受资产管理器串行保护，不能允许一次较早的异步清理在较新的同 hash 发布之后删除它。Harmony 把原版多个数据库/资产入口适配到同一个 RdbStore，且 operation reducer 可以在数据库事务内直接合并引用；“提交后先隔离规范名字，再异步删除隔离文件”是恢复同一生命周期不变量的平台适配，不声称原版逐行使用 trash rename。

## 验收约束

- 删除事务必须先提交，未提交事务不得移动或删除可恢复文件。
- 删除目标行后、事务提交前，必须确认没有其他 `note_asset` 行继续引用同一 `local_path`。
- 规范路径 detach 必须发生在数据库写者释放前。
- unlink 只能接收 detach 返回的隔离路径，不得稍后重新使用事务读取到的旧规范路径。
- detach 失败不得退化为释放写者后直接 unlink 规范路径。
- 文件根目录隔离、引用门禁、`asset -> database` 锁序与提交后通知边界继续成立。
- `d02-asset-delete-detach-boundary.mjs` 必须覆盖旧竞态模型、新顺序源码门及 canonical/legacy 共享路径所有权模型。

## 边界

进程在数据库提交后、detach 前退出，可能留下无数据库行的规范孤儿文件；同 hash 再到达时现有内容校验路径会复用一致文件，不会覆盖冲突内容。进程在 detach 后、unlink 前退出，可能留下 `assets/trash` 孤儿；它不再占用规范 hash 路径，也不会被 renderer 或资产查询引用。启动期垃圾回收、磁盘满、rename 权限失败、符号链接解析和真实并发时序仍需设备故障注入验证。
