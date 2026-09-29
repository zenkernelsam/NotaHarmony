# ADR-0974 — 导入 unzip（zip-slip 防护）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `boh` = unzip helper：`ZipInputStream`+8KB
  `BufferedInputStream`+`getNextEntry` 循环。
- **ZipSlip 防护**：`getCanonicalFile` +
  `svd.n0(path, dir+separator)` 前缀检查 →
  `IOException("Zip entry escapes target directory")`。
- `fag.F/G` mkdirs/touch；`l96.i0` 8KB 拷贝。

## Harmony 决策

同 zip-slip 防护保留（canonical 前缀检查）；
8KB 拷贝。

## Parity 状态

等价。

## 验证

- `d02-import-unzip.mjs`：10/10 通过。
