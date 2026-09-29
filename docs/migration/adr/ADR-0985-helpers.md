# ADR-0985 — xag hex 助手 + cxc pageId + ee8 op

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `xag` = 抽象 hex 写器（`c(long,bArr,i,i2,i3)`
  ——`ttf.toString` 的 UUID-hex 源）。
- `cxc extends xwd implements ka4,exc` = **pageId**
  （`C()→int`+`a()→String`）。
- `ee8 extends cee implements ka4` = MODIFY_PDF_FIELD
  op。

## Harmony 决策

xag→hex helper；cxc pageId 同构；ee8 op 保留。

## Parity 状态

等价。

## 验证

- `d02-helpers.mjs`：10/10 通过。
