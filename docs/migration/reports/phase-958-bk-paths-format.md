# Phase 958 报告 — `bk_paths` 磁盘格式全解

## 范围

iy0.java + zeb.e + zx0/gy0。纯审计。

## 原版发现

- `bk_paths/<noteId>/<pageId>.{dat,idx}` 追加双文件。
- blob = varint 计数 + 2bit 标志 + zigzag 增量量化 ×4096
  坐标（long 压缩点对）；1MiB 上限 + CRC32。
- idx = 24B 大端记录（site/pad/i/i2/offset/crc32）。
- 读 = mmap READ_ONLY + gy0 页态缓存。
- page.id 日志格式 %04x-%08x-%08x = site-ts-idx。

## 产出

- 证据：`phase-958-bk-paths-format.md`
- Fixture：`d02-bk-paths-format.mjs`（25/25）
- ADR-0902；全量 Replay 831 文件绿。
