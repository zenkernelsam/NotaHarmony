# ADR-0003：追加式页面恢复日志作为原版 Op Log 的过渡基础

- 状态：Accepted（过渡架构）
- 日期：2026-08-09
- 关联：D-19、D-02、ADR-0001

## 背景

ADR-0001 已把正式页面状态命名为 `page_element_snapshot`，并禁止继续把“删除整页再重写”的快照表冒充原版
ClientOp。该决定修正了存储语义，但 `OpStore` 仍只有接口，正式编辑路径没有产生任何可追加、可排序、可回放的操作记录。

Notability 1.0.3 的证据表明 ClientOp 是独立的追加存储：

- `e47.java:336-338` 创建 `ClientOp(noteId, op, ..., opId, clientTime)`，主键为 `(noteId, opId)`；
- `wp1.java:534` 使用普通 `INSERT INTO ClientOp`，重复身份不会被 replace 掩盖；
- `iq1.java:17-19` 只按 `(noteId, opId)` 删除或更新单条 op；
- `q0.java:437` 按 noteId 删除该笔记的全部 ClientOp。

原版 `op` 是二进制细粒度操作载荷，并带同步、聚合和 editor site 身份。Harmony 当前尚未完成这些语义，不能根据未知字段
猜测 FlatBuffer 映射，也不能把现有 JSON 元素快照改名为原版 op。

## 决策

新增与当前状态表完全分离的 `operation_log`：

```text
(sequence, note_id, op_id, op_type, payload, client_time)
```

- `sequence` 是本地单调自增顺序；`(note_id, op_id)` 唯一，append 使用普通 INSERT。
- 查询按 `(client_time, sequence)` 排序，解决同毫秒写入顺序不确定。
- v13 第一阶段曾接入 `PAGE_SNAPSHOT/NPS1`，它包含 pageId、revision 及完整有序元素。该 codec 保持可读，用于兼容已生成的
  本地恢复点，但不再作为每次保存的默认载荷。
- 第二阶段正式保存改写 `NPM1` 页面 mutation：记录 from/to revision、受影响元素的 before/after payload，以及页面完整
  before/after 身份层序。新增、删除、替换和纯重排分别使用明确 opType，不再为未变化元素重复保存 payload。
- mutation replay 必须同时匹配源 revision、完整源层序以及所有受影响源元素字节；任何不匹配、重复身份、矛盾层序、截断、
  尾随、非法 UTF-8 或超预算载荷均拒绝。相同 mutation 可严格正向或反向回放。
- 页面快照替换、revision 增长、搜索索引更新和日志 append 必须在同一 SQLite 事务内完成。任一步失败全部回滚。
- 新 opId 为 note 范围内确定性的 `page-mutation:{pageId}:{fromRevision}:{toRevision}`，避免重试生成第二个身份。它不是原版
  `timestamp/siteId` 组合，不用于声称同步等价。
- 因当前增量接口只有 `sinceTime`，正式保存会在事务内分配 `max(wallClock,lastClientTime+1)`，确保严格 `>` 游标不会因同毫秒
  或系统时钟回拨漏 op。`sequence` 仍提供数据库内稳定次序。
- 写入前逐项比较 elementId、kind、顺序和 payload 字节。完全相同的页面不增加 revision，不重写索引，也不追加恢复点。
- 第三阶段新增 `NPG1` 页面结构 mutation。它保存 note 范围的 from/to `structure_revision` 和完整 before/after
  `PageInfo` 有序集合，分别映射 `CREATE_PAGE`、`DELETE_PAGE`、`UPDATE_PAGE`、`REORDER_PAGES`。replay 必须逐字段匹配
  当前页面集合和 revision，支持严格正向与反向恢复；重复页面、非连续 pageIndex、复合设置加重排、非规范数值、截断或尾随载荷
  均拒绝。
- v14 在 `note_meta` 增加 `structure_revision`。opId 确定生成为
  `page-structure:{fromRevision}:{toRevision}`；页面写入、revision 条件推进和日志 append 同事务，失败整体回滚。普通新建笔记的
  默认首页也在笔记创建事务内产生 `0→1` 的 `CREATE_PAGE`，导入专用空笔记则由逐页导入依次产生页面 op。
- `PageRepository` 的设置写入不再修改 `page_index`；排序必须经过完整成员集合校验。删除不存在页或最后一页、更新不存在页、
  重排中的重复/缺失/外来 ID、以及任何影响行数异常都会在提交前失败。无变化设置和无变化排序不推进 revision、不追加日志。
- 第四阶段把内存历史变化作为保存队列的动作边界。`UndoRedoManager` 在成功 push、commitUndo、commitRedo 后推进单调
  history revision；`NoteCanvasView` 只在该 revision 变化时要求 `LatestWriteQueue` 保留边界。带边界的待写快照按 FIFO 保存，
  失败后回到队首且不能被较新状态取代；没有新历史动作的生命周期/离页等普通完整快照仍可合并为最新状态。Undo/Redo 必须先
  成功迁移历史栈再排队保存；页面动作继续由 `PageRepository` 的 NPG1 事务记录，不重复生成元素 mutation。
- 第五阶段为 `operation_log` 增加可空且必须全有或全空的 `action_id/history_effect/coalesce_track/action_time`。旧 NPS1/NPM1/NPG1
  行保持四列全空，只参与文档状态 replay，不猜测为历史动作。新元素动作的 NPM1 在同一事务内记录 PUSH；后续 Undo/Redo
  mutation 复用原 actionId 和原 actionTime，只把 effect 写为 UNDO/REDO。track 只采用原版 `pnf` 已证明的 NONE、INSERT_TEXT、
  REMOVE_TEXT、CREATE_INK 域；当前仅对独立落笔标记 CREATE_INK，未获证明的动作保守使用 NONE。
- v13 的建表 SQL 冻结为历史常量，不再引用会演进的最新 DDL；否则跨多个版本升级会提前创建未来列并在后续 ALTER 时失败。
- 持久化历史 reducer 按日志顺序合并同一事件的连续 mutation，并严格执行 PUSH 建栈、UNDO 只移动 undo 栈顶、REDO 只移动
  redo 栈顶。未知 action、重复 PUSH、stale/乱序移动、非法枚举/时间/身份及跨 legacy 行拼接均作为损坏拒绝，不能静默整理成
  看似可用的历史。
- 第六阶段让单事务页面动作在写库前预留 actionId，NPG1 与页面修改原子写入后才用同一元数据 push 内存栈；页面 Undo/Redo
  也在应用前从栈顶取得原 actionId/effect，数据库成功后才 commit 栈移动。ADD_PAGE、PAGE_SETTINGS、REORDER_PAGES 已接入。
  DELETE_PAGE 暂不携带历史元数据：其 Undo 需要跨 add page、restore content、reorder 三个现有事务，缺少耐久内容 checkpoint 时不能
  谎称原子 action。legacy NPG1 会成为 reducer 边界，清空边界前的可恢复栈，只暴露最后一段完整元数据历史。
- 第七阶段把 reducer 最后一个完整 segment 物化为可执行历史。元素动作保留原始 NPM1 列表，并要求 note/page、action 元数据、
  opType 与载荷分类及相邻 revision 全部一致；ADD_PAGE、PAGE_SETTINGS、REORDER_PAGES 分别转回现有页面 action，DELETE_PAGE
  继续拒绝物化。ADD_PAGE 仅接受至少已有一页时追加的空白尾页，默认首页的 legacy CREATE_PAGE 不会被伪装成可撤销动作。
- `UndoRedoManager.restore()` 在替换活动栈前完整校验动作身份、元数据与重复 actionId，保留 reducer 给出的 undo/redo 栈顺序、原
  actionId、actionTime 和 coalesce track，并按现有动作数/估算字节预算从最旧 undo 端淘汰。恢复本身不产生新的 history revision
  或 PUSH 事件；恢复后的实际 Undo/Redo 才继续用原身份写入 UNDO/REDO mutation。
- `NoteCanvasView` 首次载入笔记时读取并物化持久历史；读取结果只有在 page load generation 仍有效时才一次性安装，迟到的旧页面
  读取不能清空新页面刚恢复的栈。损坏历史只禁用 Undo/Redo，不阻止打开当前快照。恢复的 NPM1 Undo 按逆序反向回放，Redo 按
  正序正向回放；回放先在局部完整有序元素集上完成，全部匹配后才安装，并重算文本/形状 bounds，避免半应用状态。
- 第八阶段把数据库升至 v16，为 DELETE_PAGE 增加以 `(note_id,action_id)` 标识的耐久 checkpoint。checkpoint 头保存完整
  `PageInfo`、内容 revision、可空搜索 revision 和原 action time；子表保存原始元素 BLOB/层序/revision 及页面搜索行。外键只指向
  `note_meta`，不指向将被删除的 `page_info`，因此正常页面级联删除不会误删历史内容。
- DELETE_PAGE 的 PUSH 先 flush 当前页，再在单一 `PageRepository` 事务中写 checkpoint、删除页面、压紧 pageIndex、推进结构 revision
  和追加 NPG1；Undo 在一个事务中恢复页面元数据、原位置、元素、搜索行/索引状态并追加 CREATE_PAGE NPG1；Redo 先逐字段、逐 BLOB
  核对当前页面与原 checkpoint，再原子删除并追加 DELETE_PAGE NPG1。数据库成功后才发布或移动内存历史栈，旧的
  add→save→reorder 多事务补偿路径已移除。
- checkpoint 读取严格验证 header、连续层序、元素 revision、codec kind/elementId、搜索类型和源状态。DELETE_PAGE 只有找到相同
  note/action/page/time 的 checkpoint 才能被持久历史物化；缺失、歧义、损坏或与 NPG1 矛盾时禁用该段历史，不安装半恢复动作。
- 原版 `qnf`/`vnf` 的约束仍是一个 Undo action 拥有完整 forward/reverse op 列表；本阶段恢复的是该原子边界，不把 Harmony 旧有的
  UI 补偿步骤保留为产品语义，也不据此声称已经完成原版 grouped Undo 或 ClientOp 同步格式。
- 第九阶段按原版 `pnf`/`vnf` 恢复命令时分组：INSERT_TEXT/REMOVE_TEXT/CREATE_INK 的相邻窗口分别为 2000/2000/10ms，比较锚点
  随每个纳入动作移动，窗口边界包含等值；push 时不永久合并身份。Undo 选择栈顶后按新到旧移动，Redo 从对应 redo 栈顶按旧到新
  移动，整组在完整身份/元数据校验通过后才一次性改变内存栈。
- 当前 Harmony 会产生 coalesce track 的实际编辑动作只有独立落笔 CREATE_INK。同一页组在应用前 flush 已排队的 PUSH 边界，逐动作
  严格校验并形成中间页面状态；一个 SQLite 事务为每个原 actionId 顺序追加独立 NPM1 UNDO/REDO、连续推进 content revision，并只
  发布最终 snapshot/search 状态。组内任一步、日志写入或来源快照核对失败会回滚数据库并恢复执行前画布，历史栈不移动。
- 持久 reducer 不引入新的“组合 actionId”；连续移动事件仍引用每个原身份，因此重启后 Undo 的 `newest→oldest` 与 Redo 的
  `oldest→newest` 顺序可还原。跨页 coalesced 执行以及尚未建模为逐次文本 op 的 INSERT_TEXT/REMOVE_TEXT 仍不作完成声明。
- 第十阶段把数据库升至 v17，并新增独立于 `operation_log` 的本地 `history_checkpoint`、action 与 operation 子表。checkpoint 保存
  已严格归约的 undo/redo 栈、legacy 计数及覆盖到的全局 sequence；启动只归约 checkpoint 之后的 tail，避免每次打开都重放整张日志。
  checkpoint header、连续栈/operation 索引、action/op 唯一身份、PUSH 元数据、客户端时间和水位对应的本 note 日志行均严格校验。
- checkpoint 每积累 256 条 tail operation 后，在首次加载或成功显式 flush 后以最佳努力重建；最多保留 128 个 action，只从最旧
  undo 端淘汰，绝不静默截断 redo。替换 checkpoint 与删除不再被保留 undo/redo action 引用的 DELETE_PAGE checkpoint 位于同一
  SQLite 事务，并与页面 snapshot/history 写共享编辑持久化互斥；失败保留旧 checkpoint、旧删除页恢复点和完整日志。
- `operation_log` 此阶段有意不做物理裁剪。原版 `iq1` 只证明可按 `(noteId,opId)` 删除或更新单条 ClientOp，`q0` 只证明删除整篇笔记
  的 ClientOp；没有固定“保留 N 条”策略的证据。更重要的是 ClientOp 也是待同步队列，而 Harmony 尚无服务端 upload ACK 水位。
  在 ACK 元数据存在前按本地 Undo 窗口删日志会永久丢失未来同步数据，因此 compaction 仍明确阻塞。
- 第十一阶段补齐损坏历史的用户恢复边界。原版 `CorruptedSyncedOpException` 会明确标记损坏 synced op，`mb9.m()` 在前三次失败时
  断开并重连，重试耗尽才记录并停止；它不会把损坏 op 静默当作合法状态。Harmony 尚无远端重拉通道，因此启动同样进行三次严格
  重试（初次加重试共四次），仍失败时打开当前页面快照但禁用已保存 Undo/Redo，并明确提示用户继续编辑或重置本地 Undo 历史。
- “重置 Undo 历史”不调用 `deleteOps`。它在编辑持久化互斥内用空 undo/redo checkpoint 覆盖到当前最新 sequence，并在同一事务
  清理已无可执行 action 引用的 DELETE_PAGE checkpoint；原始 `operation_log` 和页面快照保持不变。事务失败保留旧损坏现场和全部
  恢复点，用户仍可继续编辑。重置等待期间编辑器 history busy 门禁阻止内容/页面动作，确保数据库水位与内存清栈处于同一静止边界；
  成功后只有 checkpoint 之后的新 action 重新进入可执行历史。
- 第十二阶段直接复核原版 `qo5.java`、`bs1.java`、`xq9.java`、`so5.java`、`gk4.v()` 及 `e47.java:336`：原版 op 身份是
  unsigned 32-bit timestamp 与 unsigned 16-bit editor site 的组合，比较先 timestamp 后 site，Clock 以原子计数器递增；Room 的
  64-bit `opId` 只是该二元组的 packed 表示。ArkTS 的 JavaScript number 不能无损承载全部 packed 64-bit 值，因此 v18 将身份明确
  保存为 `op_timestamp` 与 `editor_site_id` 两个受范围约束的整数，并以二元组唯一约束，不用浮点数模拟 long。新建笔记、页面结构、
  元素保存和成组历史写入全部从 note 级持久 clock 分配身份；旧的 page/revision 字符串不再作为新 opId。
- v18 新增单例 `local_editor_identity` 和 note 级 `note_sync_metadata`，保留原版静态/同步元数据中的 editor site、editor/creator ID、
  max timestamp、max server time 和 synced count，并增加本地有序 `uploaded_through_sequence/acked_through_sequence`。site 0 只表示
  原版查询中已有证据的本机未同步 fallback；真实服务端 site 解析到位前不会猜测其他 site。`OpStore` 暴露按 sequence 的有界待上传读取、
  upload 前缀推进和 ACK 前缀确认；未 ACK 的行会继续返回以支持幂等重传，ACK 不能越过已上传前缀或指向其他 note，且本阶段仍不删除日志。
- v17 升级按原全局 sequence 为旧行建立保守且单调的 site-0 timestamp 映射，保留原 opId、payload、history 元数据和物理 sequence；
  超出 unsigned 32-bit 时迁移整体失败而不截断。边修边审同时修正 `DatabaseManager` 的升级顺序：版本化旧库必须先执行冻结的逐版迁移，
  再用最新 `CREATE TABLE IF NOT EXISTS` 补表；否则旧库尚无 `operation_log` 时会提前创建最新列，随后 v15 `ADD COLUMN` 因重复列失败。
  重建表期间显式暂停外键并在提交/回滚后立即恢复，最终仍执行 `foreign_key_check`；`store.version` 与全部逐版 SQL 在同一事务提交，避免
  schema 已升级但版本号仍旧时在重启后重复执行非幂等迁移。

## 后果

`OpStore` 现在有真实实现，且正式页面保存会产生可回放的追加记录，因此旧 D-19 的“接口零实现”缺口可以关闭。日志与当前快照
原子一致，可作为后续崩溃恢复、压缩和细粒度操作迁移的基础。

这不关闭 D-02，也不等价于原版 ClientOp。元素与页面结构 mutation serializer、双向 replay、原子追加及当前会话的逐动作保存边界
已经建立；元素 NPM1 及单事务页面 NPG1 也具备 action identity、PUSH/UNDO/REDO effect、coalesce track 和原 action time。
最后一个无 legacy 的完整 segment 现在可在重启后恢复成可执行 Undo/Redo 栈，DELETE_PAGE 也具备耐久内容 checkpoint 和原子
PUSH/UNDO/REDO；当前可生成的同页 CREATE_INK 历史也具备原版式成组 Undo/Redo。本地启动 replay 与删除页恢复点增长已有上限，
损坏历史也有用户可见且不删除同步日志的本地恢复路径；同步日志本身仍保持追加式。原版式 editor site/op clock、耐久同步元数据和
upload/ACK 前缀契约已经建立，但还没有远端传输实现或服务端 site 解析。后续仍需实现：跨页/文本细粒度成组执行、基于 ACK 与 checkpoint
共同水位的安全日志 compaction、同步导入身份映射、实际上传/下载与服务端聚合。完成这些之前，不得声称具有原版协作或完整增量同步语义。
