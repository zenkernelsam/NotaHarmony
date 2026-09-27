# ADR-0812 — 纸张/PDF 子模式登记（k3a/n3a/hu1/wa0/xw9/ge8）

## 状态

accepted（文档+fixture，无源改动；Harmony 枚举与写手已等价）

## 原版契约（`decompiled_1.0.3`）

- `ge8` MODIFY_PAGE：f0=pages(SeqId 向量)、f1=lxc moveTo、
  f2=m2d background（内嵌 nz9）、f3=oz9 bookmark。
- `k3a` 纸张表（nz9.f0）：f0=n3a 纸纹、f1=Float 间距、
  f2/f3=Boolean、f4=hu1 RGBA、f5=cmf。
- `n3a` = {LINES,DOTS,GRID}；`hu1` = 4B RGBA struct；
  `xw9` = {DOWNSCALING_AND_MAX_BOX, DOWNSCALING_AND_CROP_BOX,
  FIT_AND_CROP_BOX}。
- `wa0` PDF 资产：f0=ua0、f1/f2=String、f3=int 默认 0。

## Harmony 决策

- `OriginalPaperFlair`/`PaperTemplate` 三枚举等价 n3a；
  `flairBleeds: template !== LINES` 保留线纸不出血语义。
- `OriginalModifyPagePayloadEncoder` 注释与 ge8 字段逐项对应
  （pages/moveTo/m2d/oz9），含 `egh.a(null)` 空背景写法。
- xw9 PDF-fit 语义登记；ua0/m2d/lxc/cmf 深层字段留档备查。

## Parity 状态

等价（枚举与 ge8 字段图）；深层子表已登记。

## 验证

- `d02-paper-pdf-schema.mjs`：23/23 通过。
- 全量 Replay 与双 HAP 构建见 Phase 868 提交。
