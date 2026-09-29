# Phase 994 报告 — `z5c.y` 文本锚点解析器

## 范围

z5c.y/u3c/xhe/cie。纯审计。

## 原版发现

- `z5c.y` = 锚点→矩形解析：null id→页边距文本区；
  非 null→双实体索引 `a79.E.I`/`a79.I` 查 xhe→cie
  →ry0 布局行高+vy7 边距+fqa 页偏移合成 u3c。
- 缺实体 → TEXT 日志+null（fail-soft）；高≥1.0f 钳制。
- PAGELESS 模式 y 起点 0；缺 size 取 `m09.b` 默认。

## 产出

- 证据：`phase-994-text-anchor-resolver.md`
- Fixture：`d02-text-anchor-resolver.mjs`（12/12）
- ADR-0938；全量 Replay 见本提交。
