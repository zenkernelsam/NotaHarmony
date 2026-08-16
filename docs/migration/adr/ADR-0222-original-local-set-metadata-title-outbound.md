# ADR-0222：本地标题编辑写原版 `SET_METADATA.title`

## 状态

Accepted，2026-08-16。

## 背景

Harmony 的标题编辑此前只更新 `note_meta.title`、`updated_at` 与搜索索引，没有原版 operation、title LWW
winner 或持久 Undo。原版 1.0.3 的 `dp → dhh → xj2 → l2d` 路径明确生成 payload type 1
`SET_METADATA.title`；`v69` 把它写进独立 `titleRegister`，DEX `vnf.c()` 又证明 Undo 会读取旧标题并生成新的
同类 operation。

仅做数据库字段补丁会让本机显示、私有同步、LWW winner 与跨会话 Undo 四条状态链分叉。另一个边修边审问题
是现有 reducer 虽能 decode title，却强制要求 pageBackground；若只放开 preflight，旧 apply 又会把缺省背景
误当 explicit-null，导致每次改标题都重置纸张。

## 决策

1. 标题 draft 与 wire 使用不同上限：编辑路径最多 200 UTF-16 code units，wire 接受 1..256。exact empty
   提交为原版资源值 `New Note`；不 trim，纯空格标题合法。
2. 200-unit 截断若落在 surrogate pair 中间则回退一个 code unit，避免产生损坏 Unicode；wire writer 还要求
   UTF-8 round-trip，并以 1024 bytes 为最大预算。
3. `encodeOriginalSetMetadataTitle()` 写 `l2d.field0 → z2d.field0`，同时让 `l2d.field1` 缺省。title-only
   operation 绝不表示背景 explicit-null。
4. `OriginalSetMetadataOperationApplier` 按字段存在性独立读取、比较和写入 title/background winner。完全没有支持
   字段才 defer；缺省字段不得参与 merge 或物化。title winner 成功时原事务内同步更新 `note_meta.title` 与
   `search_item` 标题行。
5. `persistOriginalNoteTitle()` 在共享数据库 writer 与单一 SQLite transaction 中：校验当前/请求标题、分配
   operation identity、包装完整 `uq9`、调用生产 reducer、验证 materialized title 与 structure revision、
   单调更新 `updated_at`，再追加 upload-immediate `ORIGINAL_SET_METADATA` 与可选 NTL1 history companion。
6. `UPDATE_TITLE` 仅是 Harmony durable-history companion，保存 selected page、before/after 与相邻 revision；
   它不上传，也不代替原版 operation。`ORIGINAL_SET_METADATA` 对 `PersistentHistory` 透明。
7. runtime 新增 `NOTE_TITLE` action。PUSH/UNDO/REDO 每次都调用 `updateNoteTitle()`，因此每次生成新的原版
   identity/winner；跨会话恢复从 NTL1 重建同一 action。
8. `NotePage` 串行化 onSubmit、onBlur、返回和 teardown 触发的保存；返回会等待已经由 submit/blur 启动但尚未
   完成的事务。失败不会毒死队列，旧保存完成也不能覆盖新一轮正在编辑的 draft。保存失败恢复权威标题并
   显示提示；若数据库已提交、仅运行时 Undo 栈 push 失败，则保留已提交标题并记录同步错误，不能制造
   “界面旧、数据库新”的假回滚。
9. `NoteRepository.updateNote()` 保留旧接口，但实现委托给 title operation；新建 UI 的默认标题改为
   `New Note`。创建时 combined title/background bootstrap 另行追完整调用链，本 ADR 不假装已经闭环。

## 结果

- 本地标题编辑、搜索索引、最近修改时间、title LWW winner、上传 operation 和持久 Undo 同事务提交。
- title-only payload 不再被错误 defer，也不会重置 note background。
- 空标题、纯空格、200/256 边界与 Unicode 行为有明确且可 replay 的契约。
- PUSH/UNDO/REDO 的三个可见状态对应三条新的原版 `SET_METADATA.title`，而不是回写旧快照。
- reducer defer、identity 冲突、revision 异常、搜索写入或 operation append 任一步失败都会整事务回滚。
- submit/blur 后立即返回不会越过在途标题事务；提交后的 runtime-history 异常也不会回滚已持久化 UI。

## 被拒绝的方案

- 继续直接 `UPDATE note_meta`：没有原版 operation、winner 或跨会话 Undo。
- 用 Harmony `UPDATE_TITLE` 作为上传协议：它只是本地恢复 companion，不是原版 payload。
- 对标题调用 `trim()`：会错误拒绝原版允许的纯空格标题。
- 让缺省 pageBackground 走 explicit-null：会在改标题时静默重置纸张 winner。
- 把 UI 200 上限当成 reducer 200 上限：原版 wire validator 明确接受到 256。
- 仅凭 `zm7` 一行立刻改写创建 bootstrap：尚未闭环初始 operation 顺序、背景来源和失败补偿。

## 验证与后续

- ArkTS fixture 覆盖 title-only FlatBuffer、中文/emoji、200/256、exact-empty、纯空格与 NTL1 round-trip；
  `PersistentHistory.test.ets` 覆盖跨会话 title action materialization。
- `d02-local-set-metadata-title-outbound.mjs` 覆盖原版源码契约、独立 FlatBuffer 解析、字段独立 LWW、搜索、
  单调时间、PUSH/UNDO/REDO、history transparency 与注入故障回滚。
- 原版线性证据见
  `docs/migration/evidence/original-local-set-metadata-title-outbound-jadx-2026-08-16.md`。
- 本阶段不运行设备、模拟器、虚拟机或 Hypium；真实 UI 竞态、系统返回手势、多端 title LWW 与上传 ACK 留待
  集中真机验收。

## Phase 246 Follow-up

本 ADR 刻意保留的创建 bootstrap 边界现已由 ADR-0223 闭环。原版 `id7.d()` 不是复用 title-only writer：
它先读取 `selectedDefaultTemplate`，在同一 `SET_METADATA` 同时写 title 与 concrete pageBackground，再按 List
顺序追加 `CREATE_PAGE(pageCount=2)`。既有笔记标题编辑仍必须保持本 ADR 的 title-only 语义；只有普通新笔记
bootstrap 使用 combined writer。
