# ADR-0957 — 文件夹子系统

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 三表：SyncedFolderMetadata{siblingOrder REAL,
  emoji}、ClientFolderEdit{稀疏字段+idempotencyKey+
  uploaded}、ClientFolderDelete{childrenHash 墓碑}。
- `jp1` DAO 挂 `RawLibraryStateDatabase`（第四库）；
  `beb` 管理器。
- 实体：`jae` 同步态、`xo1 implements yo1` 稀疏编辑
  （xgb createdAt）。

## Harmony 决策

表平移；分数序/幂等键/上传标志/子树哈希保留；
上传 fail-closed。

## Parity 状态

等价（本地）；同步 fail-closed。

## 验证

- `d02-folder-subsystem.mjs`：13/13 通过。
