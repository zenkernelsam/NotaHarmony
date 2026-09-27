# ADR-0865 — 枚举 setter 族 + 枚举值全集

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- 枚举 setter 六表：o2d SetParagraphAlignment(r4a)、
  j2d SetDecoratorStyle(fy2)、a3d SetUInt8(cmf)、
  b3d SetWritingDirection(bcg)、n2d SetPaper(k3a)、
  p2d SetRect(bmb)。
- 枚举全集：r4a alignment **1 基**{LEFT,CENTER,RIGHT}；
  fy2 DecoratorStyle{NONE,BULLET,NUMBER,CHECK_BOX,
  BLOCK_QUOTE,CODE_BLOCK}；bcg WritingDirection{LTR,
  RTL}；ife TapePattern 9 值{STRIPES..CHECKERS}；
  ive TextWrap{PIXEL_ALIGN,NO_WRAP}；
  **cmf=Kotlin UByte**（无符号四族 cmf/mmf/ymf/tmf
  全闭）。

## Harmony 决策

枚举值与基序对齐（r4a 从 1 起）；cmf UByte 语义
对齐。

## Parity 状态

等价（枚举层实名闭合）。

## 验证

- `d02-enum-closure.mjs`：18/18 通过。
- 全量 Replay 794 文件绿，见 Phase 921 提交。
