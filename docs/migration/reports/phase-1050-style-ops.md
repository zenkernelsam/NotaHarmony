# Phase 1050 报告 — 样式操作载荷

## 范围

`me8`/`he8`/`io1` 样式操作、`r4a`/`fy2`/`bcg` 枚举、
`o2d`/`j2d`/`b3d` 包装器。纯审计。

## 原版发现

- ModifyStyle 15 字段：bold/italic/underline/highlight/
  familyName/size/foregroundColor/link/上下标/
  strikethrough/code；familyName 非空、size>0。
- ModifyParagraphStyle 10 字段：indentLevel/alignment/
  lineSpacing/decoratorStyle/isChecked(deprecated)/
  programmingLanguage/writingDirection。
- ClearStyle 校验锚点类型（Invalid start type）。
- `r4a` 对齐 1 基（0=未设）、`fy2` 装饰 6 值
  （BULLET/NUMBER/CHECK_BOX/BLOCK_QUOTE/CODE_BLOCK）、
  `bcg` LTR/RTL。

## Harmony 决策

逐条保留；isChecked 废弃语义保留。

## 产出

- 证据：`phase-1050-style-ops.md`
- Fixture：`d02-style-ops.mjs`（12/12）
- ADR-0994；全量 Replay 见本提交。
