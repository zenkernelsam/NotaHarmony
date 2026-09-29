# ADR-0938 — `z5c.y` 文本锚点解析器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `z5c.y(qo5, x09)` → `u3c`{anchor, 位置 ei3, 尺寸 di3}。
- null id → 页级锚：`nz9` PageBackground margins +
  PAGELESS 特判 + `m09.b` 默认 size。
- 非 null → `a79.E.I`/`a79.I` 双实体索引查 `xhe`→`cie`，
  未命中 `yn7.TEXT` 日志+null；命中则 ry0 布局行高
  +vy7 边距+fqa 页内偏移合成矩形（高≥1.0f 钳制）。

## Harmony 决策

等价语义；Harmony 行高由 ParagraphLayout/measure 提供。

## Parity 状态

等价。

## 验证

- `d02-text-anchor-resolver.mjs`：12/12 通过。
