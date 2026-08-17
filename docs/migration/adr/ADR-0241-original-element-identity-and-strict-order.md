# ADR-0241：原版元素 ID 身份与严格页面层序快照

## 状态

Accepted - Phase 263（2026-08-17）

## 背景

M2-R-09 早期已经引入 `PageElementRef(kind, elementId, zIndex)`，让 Stroke、Text、Shape、Image、Math 可以交错
渲染、持久化、Undo/Redo 与导入导出。但规范化仍把 `(kind,id)` 当作唯一 key，并在损坏 order 上自动删除、补回和
重排；数据库主键也仍为 `(note_id,page_id,element_id,kind)`。这留下三类错误：

1. 同一 ID 可以分别作为 Stroke/Text 或出现在同一 note 的不同页面，直到整篇读取才暴露。
2. 显式 order 缺成员、zIndex 不连续或 kind 错误时会被“修好”，让调用方以为持久化成功。
3. row kind/ID 与 payload 内嵌 identity 不一致时，部分加载路径会跳过损坏元素，形成静默内容丢失。

原版 `vnd.equals/hashCode` 只使用实体 `getId()`；`zh9` 也以 Group ID 或叶实体 ID 作为同一个
`LinkedHashMap` key；`ssc` 的 ZIndexUnit 不含 payload kind 身份维度。完整证据见
`docs/migration/evidence/original-element-order-identity-jadx-2026-08-17.md`。

## 决策

### ID-only 身份和严格 order

- `normalizePageElementOrder()` 只为 legacy 空/旧数组迁移服务，但所有去重都按 element ID。
- 新增 `strictPageElementOrder()`：非空显式 order 必须成员完整、zIndex 连续、kind 匹配且每个 ID 恰好一次；失败
  返回 null，调用方不得自动补成员或重排后继续保存。
- `appendPageElementRefs()`、成员比较、mutation/snapshot/group/partial-erase/history codec、Undo/Redo 和编辑器
  materialization 全部使用 ID-only identity；kind 只验证 payload discriminator。
- kind 变化且 ID 相同不是同一 payload 的原地修改，而是 replacement；非法 kind 0/6 明确拒绝。

### 持久 payload 绑定

- `decodeStoredPageElement(elementId,kind,payload)` 同时验证 kind 1..5、payload 非空、payload 判别类型和内嵌 ID。
- 当前快照、整篇加载、DELETE_PAGE checkpoint、持久 history 和 repository 恢复都使用严格 decoder。
- 损坏快照不再逐条跳过元素；任一 identity/order/payload 不一致都使该操作 fail closed。

### note-wide 写入门禁

- `PageElementIdentity.reserveNotePageElementIds()` 为导入提供原子 ID 预留；任一页面冲突不会部分污染 reserved set。
- 自有 `.note` 与 Notability 导入在创建 note/页面前扫描全部页；跨页复用 ID 直接判定包损坏，不写半成品。
- `writePreparedLocked()`、`writeHistoryGroupLocked()` 与 DELETE_PAGE checkpoint restore 在同一 SQLite transaction
  查询其它 live 页面，目标 snapshot 任一 ID 已被占用即拒绝。
- 数据库升至 v64，先创建非唯一 `(note_id,element_id)` 查询索引，再安装 `BEFORE INSERT` 与 identity-field
  `BEFORE UPDATE` trigger，使原版 reducer、页面恢复和未来新增 repository 也不能绕过 note-wide identity；索引让
  批量插入时的 trigger `EXISTS` 查询按 identity 定位，而不是对同一 note 反复全扫。

### hidden/archived 原版实体与 Group 身份

原版 Group 和叶实体都以 operation identity 作为 ID。即使叶实体当前 hidden、页面 archived，identity 也不会因为
不在 live `page_element_snapshot` 中而重新可用：

- 入站操作以 `(note_id,op_timestamp,editor_site_id)` 为 `synced_operation_inbox` 主键；相同 identity 只有完整 bytes/
  metadata 相同才算幂等重试，不同 CREATE payload 会作为 identity conflict 拒绝。
- 本地 authoring 通过 `note_sync_metadata.max_op_timestamp` 分配下一 identity，并用 compare-and-set 更新；并发分配只有
  一个成功。editor site 一旦已有 operation/sync 状态便不能替换，保持 `(timestamp,site)` 命名空间稳定。
- 因此 active Group 与 live 叶实体由 Group consumer 显式拒绝冲突；hidden/archived 叶实体则由 durable operation
  identity 防重保证，不额外添加跨所有原版状态表的 trigger，也不在每次页面保存时扫描全部 CRDT/archive 表。

### 旧损坏库策略

不添加 `UNIQUE(note_id,element_id)`：旧库若已有重复行，创建 unique index 会使整个应用初始化失败。v64 使用的
`idx_page_snapshot_identity` 明确为非唯一索引，所以可以在重复行仍存在时创建；两个 trigger 在保留既有数据供诊断的
同时禁止新增冲突。读取整篇 note、保存冲突页面或恢复冲突 checkpoint 会明确失败；本阶段不猜测该保留哪一行，也不
自动删除用户内容。

## 后果

- 一个 ID 不再因为 kind/page 不同而被视为两个合法实体。
- 显式 order、mutation、history 与持久 row 的 identity 契约一致；损坏不会被 normalization 掩盖。
- 正常旧页面仍可由 legacy 空 order 确定性迁移；已经提供显式 order 的新路径必须严格正确。
- 旧损坏库不会在启动期整库打不开，但冲突页面也不会继续被错误覆盖或产生新的损坏。
- DB 版本由 63 升至 64；旧 v63 数据不重写、不去重，只原子创建非唯一 identity 索引并安装两个 guard trigger。

## 验证契约

- ArkTS fixture：legacy 空 order、缺成员/错误 zIndex、跨 kind 同 ID、非法 kind、row/payload identity、checkpoint、
  replacement 及 note-wide reservation。
- `d02-original-element-order-identity.mjs` 使用原版源码和内存 SQLite 实测旧重复数据上创建非唯一索引、query plan
  命中 identity index、trigger 安装、跨页/跨 kind 拒绝、普通 payload update、失败事务回滚、clipboard 严格 order、
  row/payload 绑定、Group/叶身份及 hidden/archived operation identity；专项 `TOTAL=26 FAILED=0`。
- z-order/history/group/package/partial-erase 相关 replay、全量 replay、`git diff --check`、clean 后两套 HAP 必须通过。

## 仍需设备验收

- Stroke/Text/Shape/Image/Math 交错层序的真实 Canvas 与缩略头像素。
- 保存重启、跨页切换、Undo/Redo、删除页恢复及完整自有包/Notability 导入导出。
- 损坏库的用户可见错误、恢复/导出诊断入口；本阶段只保证 fail closed，不删除或猜测修复用户数据。
