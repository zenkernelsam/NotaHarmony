# Phase 1284 证据 — ops/synced CRDT 冲突 + NoteOpsUpdaterWorker

来源：`data/note/ops/synced/*.java` + `data/library/state/
notes/NoteOpsUpdaterWorker.java`。

## CRDT 同步异常分类法

```java
StaleSyncedNoteException(ttf noteId)
    "Synced note metadata not found: "+ttf   // 元数据过期
CorruptedSyncedOpException(ttf, uq9, AssertionError)
    j0.l(ttf, uq9)                            // op 应用断言失败
AccessDeniedException(q93, p93, String)      // 403
NoteOpsNotFoundException()                   // 404
NoteHasNoOpsException                        // 空 op 集
```

→ `ttf`=笔记 ID；`uq9`=op —— op 应用到实体时断言
失败=CorruptedSyncedOp（CRDT 完整性校验）。

## `NoteOpsUpdaterWorker extends CoroutineWorker`

```java
{Context, WorkerParameters,
 ya9 noteOpsRepository,      // op 仓库
 veb rawNoteMetadataRepository, // 原始元数据
 vg3 diskQuotaRepository,    // 磁盘配额
 wt9 opsDownloadPriority}    // 下载优先级
doWork → 下载/应用远端 op，查磁盘配额，按优先级
```

## 语义

**CRDT 同步工作器** —— NoteOpsUpdaterWorker 拉远端
`uq9` op → 应用到本地文档；冲突分类法区分 403/404/
过期元数据/op 损坏 —— op 应用有断言校验（CRDT
不变量：连续 op、有效实体引用）。

## Harmony 决策

CoroutineWorker → `WorkScheduler`；同步冲突异常 →
Harmony `BusinessError` 分类 —— CRDT 同步+冲突
语义保真。

## 产出

- fixture `d02-sync-conflict.mjs`（10 断言）。
- ADR-1228；中文报告。
