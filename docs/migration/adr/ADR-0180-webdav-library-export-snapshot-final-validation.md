# ADR-0180：WebDAV 整库导出快照最终复核

## 决策

WebDAV 备份在生成任何 `.note` 前，先排空进程内所有 `StrokePersistence` 页面保存队列，并记录全局保存
入队 generation。随后用一条 note/page SQL 读取初始资料库快照；每篇笔记仍保留导出前后 revision
复核，全部 ZIP 生成完成后，再用同一条 SQL 取得一次完整资料库快照并进行集合级比较。只有以下状态全部
一致时，生成的包才允许进入远端发布器：

- 笔记 ID 集合、标题、`createdAt`、`updatedAt`
- `structure_revision`
- 页面顺序、纸张、方向、宽高、页面背景、PDF 页身份
- 每页 `content_revision` 与元素数量
- 导出期间没有新的编辑保存入队，且没有仍处于 dirty 的进程内保存队列

revision 使用固定长度 `v2:<SHA-256>`。摘要输入是上述规范化笔记状态，而不是把所有页面字段直接拼入
manifest，避免大笔记令备份清单无界增长。历史同步数据允许 `createdAt == 0`；当前批次协议要求的
`updatedAt` 仍必须为正整数。

导出准备阶段单独捕获错误：快照变化提示用户等待保存后重试，其他本地数据库、ZIP 或资产准备失败提示
无法准备完整本地包。只有已经进入 WebDAV 发布阶段的异常才使用服务器不可达诊断。

## 原因

旧实现只在每篇导出前后比较该篇 revision。若先导出 A，再导出 B/C，而 A 在 B/C 期间变化，A 自己的
前后检查已经结束；最终仍可能把不属于同一资料库时刻的 A/B/C 发布为一个“完整”批次。单篇检查不能
替代整批最终门禁。

在整个 ZIP 构建期间持有数据库读事务会令长时间文件压缩阻塞正常编辑，也容易与现有页面保存、原版
operation 和资产事务形成不合适的锁所有权。两次 statement-level 原子快照、单篇检查和保存 generation
组合，可在不持有长事务的前提下拒绝已知变化。

进程级保存队列注册表只保留 dirty/running 队列。`LatestWriteQueue` 真正变为 idle 时主动注销；失败队列
继续保留以便 `flushAll()` 暴露并重试。否则静态注册表会长期强引用浏览过的页面队列与其 persistence
实例，形成由本修复自身引入的内存滞留。

## 原版证据与平台边界

Android 原版 Notability 1.0.3 没有 Harmony WebDAV 批次导出代码，不能把本决策描述为原版备份实现的
逐行移植。原版证据仅约束资料库身份与元数据语义：

- `RawLibraryStateDatabase_Impl.java` 注册 `SyncedNoteMetadata` 等资料库状态表；
- `defpackage/e47.java` 声明 `SyncedNoteMetadata` 的 `id/title/createdAt/updatedAt` 非空持久字段；
- `defpackage/cha.java` 的更新语句把这些字段作为同一笔记元数据记录写回。

Harmony 因而将 ID、标题和时间纳入导出签名，同时用本地 `structure_revision`、页面 revision 与元素计数
覆盖当前包真正序列化的结构和内容。WebDAV 的批次最终复核仍是 Harmony 扩展协议的可靠性设计。

## 资产并发边界

图像/PDF 的 hash、大小和 MIME 随页面元素或背景进入导出数据；资产到达路径在 SHA-512 校验后以原子文件
发布，并拒绝已存在内容冲突。本决策不在漫长 ZIP 构建期间持有 `assetMutationMutex`，避免冻结下载、导入
和删除路径。正常应用写入不会原地改写一个已发布 hash 文件；缺失或大小不符会令单篇导出失败，笔记或
页面引用变化也会被最终快照拒绝。

真实文件被外部同大小替换、文件系统损坏，或设备级删除/读取竞态仍属于故障注入边界；当前 revision 不
直接摘要 `note_asset` 行或重新计算每个导出资产的 SHA-512，不能宣称已覆盖这些情形。

## 验收边界

ArkTS 单测与 replay 覆盖集合新增/删除、早期笔记后变、元数据变化、重复身份、epoch-zero 时间、进程内
保存 generation、最终原子查询、本地错误分类和 idle 队列注销。真实大资料库编辑压力、磁盘满、文件
损坏、应用被杀以及 WebDAV 断流仍需设备与故障注入测试。
