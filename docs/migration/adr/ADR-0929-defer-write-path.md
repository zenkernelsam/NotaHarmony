# ADR-0929 — Defer 写路径（schema 门控 + 原子提交）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `nce.g`：u16 无符号 schema 比较——**文件 schema 高于
  本端时不物化**，blob 原样落盘+元数据行（size+CRC32）；
  ≤本端走物化+Room 事务。空 blob 拒绝 defer。
- `nce.u`：`zae.a()`→x63 格式（null=IllegalState
  "Should be impossible"），`hce` λ 在 `pv2.c` Room
  事务内完成**文件写+SyncedOpMetadata 行插入**原子提交，
  日志带 new.schema/current.schema。
- `crb` case17：`fsi.z` 父目录 + `WRITE+CREATE_NEW`
  排他创建 + 全量写循环；case18：qud 下载原子改名+N 防重。
- `w63.a`：格式枚举名↔x63 转换，未知值抛错。
- `ebe`：SUCCESS / CORRUPT_NEEDS_REDOWNLOAD。

## Harmony 决策

等价：schema 门控 defer + 排他写 + 事务原子提交；
CRC32/size 校验链入库。

## Parity 状态

等价。

## 验证

- `d02-defer-write-path.mjs`：19/19 通过。
