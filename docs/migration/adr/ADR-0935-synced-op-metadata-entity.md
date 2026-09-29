# ADR-0935 — `pae` SyncedOpMetadata 实体

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `pae` = 17 字段实体，与 SyncedOpMetadata 17 列
  **顺序一一对应**（id..offsetsChecksum）。
- 关键类型：h=xgb Realtime(maxServerTime)、
  j=qo5(titleOpId)、o=Set\<hg4\>(fingerprintFileLengths)、
  p/q=ops/offsetsChecksum、n=schemaVersion。
- `pae.g` = Kotlin copy() 位掩码局部更新。
- `ye9` 接口：`a()`=createdAt 审计契约。

## Harmony 决策

等价：实体全字段对齐 RDB；指纹集合作关联集合存储。

## Parity 状态

等价。

## 验证

- `d02-synced-op-metadata-entity.mjs`：9/9 通过。
