# ADR-0267：多图照片插入共享一个持久历史动作

- 状态：Accepted（Phase 289，2026-08-23）
- 范围：原版多选照片导入、durable companion history、运行时 Undo/Redo action
- 相关：ADR-0258（单图插入原子持久化）、ADR-0265（Transform Undo 资产刷新）

## 决策

一次多图照片导入仍是一个逻辑 ADD_ELEMENTS 历史 action。每张图片继续使用独立 SQLite 事务和
独立 ORIGINAL_CREATE_BLOCK，因为资产准备、文件 fsync 和页面 revision 必须逐张落地；但这些事务
复用同一个 prepared HistoryMetadata.actionId。持久 reducer 按相邻相同 metadata 分组，并校验同页、
revision 连续与操作类型一致。

运行时最终 ADD_ELEMENTS action 必须携带全部新增 image refs。ddedElementOrder 从最终页序中按
插入顺序提取，zIndex 接在捕获的 lementOrderBefore.length 之后；不能留空数组，否则状态校验会拒绝
Undo/Redo 并造成 UI 与 durable history 脱节。

## 原版证据与 Harmony 边界

- 原版 yr.java 保持 photoUris 顺序；gj.java 对 URI 列表执行 all-or-nothing 校验；
- 原版未暴露本阶段涉及的 SQLite/history companion 结构；持久分组属于 .note 导入链的 Harmony 扩展；
- 本决策只声明同一逻辑动作的 Undo/Redo 与持久重放一致性，不声称跨图 SQLite rollback；任一张失败时，
已提交的前序图片保持已入库状态。

## 验证边界

- 新增 Replay 固定 runtime order、actionId 分组和 revision 连续校验；
- ArkTS fixture 注册进 Hypium 套件；真实设备多选导入仍开放；
- T-042 继续保留为整个 Goal 最后一项。
