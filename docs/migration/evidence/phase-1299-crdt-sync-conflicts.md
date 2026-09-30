# Phase 1299 证据 — CRDT 同步冲突异常分类 + 元数据库

来源：`data/note/ops/synced/*` + `ops/database/
NoteBundleMetadataDatabase*`。

## `ops/synced/` —— 同步冲突异常分类法

```
AccessDeniedException(q93)          — 访问拒绝（403/权限，
                                      q93=枚举状态）
CorruptedSyncedOpException          — op 应用断言
  (ttf, uq9, AssertionError)          （Phase 1284）
NoteHasNoOpsException               — 笔记无 ops
NoteOpsNotFoundException            — ops 缺失
StaleSyncedNoteException(ttf)       — 过期笔记（同步竞态，
                                      ttf=元数据）
```

完整 **CRDT 同步冲突分类法** —— 权限/损坏/无-ops/
缺失/过期竞态全覆盖。

## `ops/database/NoteBundleMetadataDatabase` = 第 8 个
Room 库 —— 笔记 bundle 同步元数据。

## `q93`=枚举（访问状态）；`ttf`=`Comparable`+`Serializable`
元数据记录。

## 语义

CRDT 同步的**失败边界** —— 每种同步/合并/应用失败都
有专属异常 → 上层据此做失败策略（重试/冲突解决/降级）。

## Harmony 决策

CRDT 冲突异常 → `BusinessError` 或自定义 Error 子类
（fail-closed 传播同步失败）；元数据库 → RdbStore —
— 同步冲突语义保真。

## 产出

- fixture `d02-crdt-sync-conflicts.mjs`（10 断言）。
- ADR-1243；中文报告。
