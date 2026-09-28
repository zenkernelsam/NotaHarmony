# ADR-0902 — `bk_paths` 笔迹 blob 磁盘格式

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`bk_paths/<noteId>/<pageId>.{dat,idx}` 追加式双文件：

- **blob**（dat）：varint 路径数 → 每路径 varint 元素数 +
  2bit 标志打包（4/字节）→ zigzag-varint **增量编码**坐标
  （f32 量化 ×4096，x/y 存 long 压缩对）。1MiB 上限。
- **idx**：24B 大端记录 `{site:u16, pad, i:int, i2:int,
  offset:long, crc32}`——与 LE 线格式相反。
- 读：mmap READ_ONLY 缓存于 `gy0.c`；IOException → 重建。

## Harmony 决策

自研磁盘格式全平台无关，可复刻；mmap→普通文件读或
CoreFileKit 映射。与 FlatBuffer 线格式正交。

## Parity 状态

格式等价可实现；Harmony 存储层待对齐（按既有存储决策）。

## 验证

- `d02-bk-paths-format.mjs`：25/25 通过。
- 全量 Replay 831 文件绿，见 Phase 958 提交。
