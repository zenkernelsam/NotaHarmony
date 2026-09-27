# ADR-0811 — 页面 payload 模式登记（ln2/nz9/sw9 + 子结构）

## 状态

accepted（文档+fixture，无源改动；Harmony CreatePage 写手已等价）

## 原版契约（`decompiled_1.0.3`）

- `ln2` CreatePage payload：f0=cxc 位置、f1=nz9 外观、f2=
  pageInAsset int（默认 1）、f3=oz9 bookmark byte（越界回退
  UNBOOKMARKED 的安全枚举解码）。
- `nz9` 外观表：f0=k3a 背景、f1=sw9 PDF-in-asset、f2=float、
  f3=qed（2-float 尺寸）、f4=vy7（4-float 颜色/矩形）。
- `sw9` PDF 表：f0=wa0 资产、f1=xw9 范围、f6=qed 页尺寸向量，
  `n()` = PDF 总页数（页内偏移基准）。
- `mmf` inline int 值类（pageInAsset 序数）、`k3a` 背景子表
  （hu1/n3a/Boolean×2）。

## Harmony 决策

`OriginalCreatePagePayloadEncoder` 已按 ln2 vtable 逐字段写出，
cxc 12B 结构（site@0/ts@4/index@8）精确一致，注释标注原版表名
与 `wz9.u`/`haj.a` 回写路径。nz9 深层子字段由
`OriginalDefaultTemplate`/`PageBackgroundModel` 承载等价模型；
sw9/子表逐字段审计留档本阶段证据备查。

## Parity 状态

等价（ln2 写手）；nz9/sw9 深层字段已登记、后续阶段逐字段核销。

## 验证

- `d02-page-payload-schema.mjs`：24/24 通过。
- 全量 Replay 与双 HAP 构建见 Phase 867 提交。
