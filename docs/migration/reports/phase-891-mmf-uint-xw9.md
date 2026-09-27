# Phase 891 报告 — `mmf`/`xw9` 实名

## 范围

实名两个贯穿纸面/PDF 子图的值类。纯审计，无源改动。

## 原版发现

- `mmf` = Kotlin UInt 值类（无符号格式化+比较）；全部
  包装点（pageCount/页数×3/fileSize）= UInt32 语义。
- `xw9` = PDF 布局行为 byte 枚举三值：
  DOWNSCALING_AND_MAX_BOX=0 / DOWNSCALING_AND_CROP_BOX=1 /
  FIT_AND_CROP_BOX=2（默认）。

## Harmony 核对

无符号读取一致；PDF 适配三值对齐；默认 FIT_AND_CROP_BOX。

## 产出

- 证据：`phase-891-mmf-uint-xw9.md`
- Fixture：`d02-mmf-uint-xw9.mjs`（14/14）
- ADR-0835；全量 Replay 764 文件绿。
