# Phase 1090 报告 — e4c 文本容器（修正）

## 完成内容

- **修正 1066**：`e4c` = 文本块宿主（非组集合）：`exc`
  锚点 + UTF-8 CharsetDecoder（REPORT 非法字节）+
  `s3c`/`hr5`/`swc` 片段 + `m4c.D` 物化。
- 文本 = UTF-8 字节流 + exc 锚序列。

## 产出

- evidence `phase-1090-text-container.md`
- fixture `d02-text-container.mjs`（10/10）
- ADR-1034
