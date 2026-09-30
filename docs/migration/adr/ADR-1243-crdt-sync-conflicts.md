# ADR-1243：CRDT 同步冲突异常

## 状态

已接受（Phase 1299）。

## 决策

同步冲突异常 → `BusinessError`/自定义 Error 子类（fail-
closed 传播）；`NoteBundleMetadataDatabase` → RdbStore。

## 理由

`ops/synced/` 5 异常（AccessDenied/Corrupted/NoOps/
OpsNotFound/Stale）= CRDT 同步失败边界全覆盖 —— 每种
同步/合并失败专属异常驱动失败策略。

## 后果

Harmony CRDT 同步 = BusinessError 冲突分类 + RdbStore
元数据 —— 同步失败语义保真。
