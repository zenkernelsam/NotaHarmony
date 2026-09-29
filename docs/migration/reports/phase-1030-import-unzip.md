# Phase 1030 报告 — 导入 unzip（zip-slip 防护）

## 范围

`boh` zip 解压 helper + zip-slip 防护。纯审计。

## 原版发现

- `boh` = unzip：`ZipInputStream`+8KB Buffered+
  `getNextEntry` 循环。
- **ZipSlip 防护**：canonical path 前缀必须
  `dir+separator`，否则 IOException("Zip entry
  escapes target directory")——目录穿越防御。
- `fag.F/G` mkdirs/touch；`l96.i0` 8KB 拷贝；
  `o22`/`y22` 编译器 lambda。

## Harmony 决策

同 zip-slip 防护保留。

## 产出

- 证据：`phase-1030-import-unzip.md`
- Fixture：`d02-import-unzip.mjs`（10/10）
- ADR-0974；全量 Replay 见本提交。
