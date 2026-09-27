# Phase 920 报告 — setter 布局 + 枚举实名

## 范围

setter 包装表布局 + v01/tv6/dz0/y01 实名。纯审计。

## 原版发现

- setter 统一 {value@c(4)} 单槽三路态语义。
- v01=Boundary{cxc,y01} 内联结构=文本范围复合锚；
  y01=BEFORE/AFTER/START_OF_DOC/END_OF_DOC。
- tv6=LayoutMode{PAGED,PAGELESS}；
  dz0=BlockWrapSupport 三态含 LEGACY 迁移值。

## Harmony 核对

setter/Boundary/枚举对齐。

## 产出

- 证据：`phase-920-setter-enums.md`
- Fixture：`d02-setter-enums.mjs`（12/12）
- ADR-0864；全量 Replay 793 文件绿。
