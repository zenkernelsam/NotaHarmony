# Phase 991 — `pae` = SyncedOpMetadata 实体（17 字段↔17 列）

来源：`decompiled_1.0.3/sources/defpackage/pae.java` +
`wp1.java` INSERT 语句。

## 1. 字段↔列映射（顺序一致）

| # | 字段 | 类型 | 列 |
|---|------|------|----|
| 0 | a | ttf | id（noteId） |
| 1 | b | ttf | legacyId |
| 2 | c | short | editorSiteId |
| 3 | d | ttf | editorId |
| 4 | e | long | createdAt（`ye9.a()`） |
| 5 | f | ttf | creatorId |
| 6 | g | long | updatedAt |
| 7 | h | xgb | maxServerTime（Realtime） |
| 8 | i | String | title |
| 9 | j | qo5 | titleOpId |
| 10 | k | int | opCount |
| 11 | l | long | opFileSize |
| 12 | m | int | maxTimestamp |
| 13 | n | short | schemaVersion |
| 14 | o | Set | fingerprintFileLengths（hg4 集） |
| 15 | p | int | opsChecksum |
| 16 | q | int | offsetsChecksum |

## 2. `pae.g(..., mask)` = Kotlin `copy()`

11 位掩码位 64/256/512/1024/2048/4096/16384/32768/65536
分别控 g/h/i/j/k/l/m/o/p/q 字段替换——defer/物化
分支用 `g(pae, …, 114687)` 只更新部分字段。

## 3. `ye9` 接口

`a()`=createdAt——审计时间戳契约（多实体实现）。

## 4. 校验链闭环

- `k`(opCount) → `.offsets` len==k×4 + `uw7` 物化边界
- `l`(opFileSize) → `.ops` length 等式
- `p`/`q` → `z5c.i(.ops)` 与 offsets CRC32 期望
- `o`(hg4 集) → fingerprints/<site>.fp 文件指纹
- `n`(schemaVersion) → u63.c / 新文件版本跟踪

## 5. Harmony 对齐

等价：17 字段全量对齐 RDB 行；指纹集合作关联存储。

## 6. 验证

`d02-synced-op-metadata-entity.mjs` 静态断言。
