# ADR-1250：Harmony 实现覆盖

## 状态

已接受（Phase 1306）。

## 决策

Harmony 端已具备 CRDT 同步+编辑器+卡片+备份主体 —
— 原版架构对应物就位；剩余差距逐项填平。

## 理由

`note/src/main/ets/`（291 文件）：4 Ability（Note/
Backup/Form/FormEdit ≈ Activity/Widget）+ `data/`(157:
BinaryOpCodec/OperationCompaction/SyncCoordinator/
*OpCodec/Backup —— CRDT op 层实现）+ `ui/editor/`(
StylusAdapter/Canvas/PageManager) —— 主体架构已映射。

## 后果

Harmony 主体功能已映射原版；后续 Phase 聚焦具体差异/
缺口/平台降级细化 —— 覆盖核对语义保真。
