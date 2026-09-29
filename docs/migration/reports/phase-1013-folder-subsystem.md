# Phase 1013 报告 — 文件夹子系统

## 范围

三表 DDL、jae/xo1 实体、jp1 DAO、beb 管理器、
RawLibraryStateDatabase。纯审计。

## 原版发现

- `SyncedFolderMetadata`：siblingOrder REAL 分数序 +
  emoji。
- `ClientFolderEdit`：稀疏更新 + idempotencyKey +
  uploaded 默认 false。
- `ClientFolderDelete`：childrenHash 冲突检测墓碑。
- `jp1` 挂 **RawLibraryStateDatabase**（第四 Room DB）。
- `xo1`：xgb Realtime createdAt + 可空稀疏字段。

## Harmony 决策

等价平移；同步上传 fail-closed。

## 产出

- 证据：`phase-1013-folder-subsystem.md`
- Fixture：`d02-folder-subsystem.mjs`（13/13）
- ADR-0957；全量 Replay 见本提交。
