# Phase 885 报告 — `x09`/`a79` 物化文档模型

## 范围

登记 u5j 工厂消费的文档模型。纯审计，无源改动。

## 原版发现

- `x09` = 标记接口；`a79` = 物化实现（yc6 寄存器×8 +
  f1a 序模型 + 实体索引族）。
- 七具名属性（KProperty）：title/fontFamily/fontSize/
  alignToLines/layoutMode/blockWrap/handwritingLanguage
  = l2d SET_METADATA 面；第八寄存器 = 背景 nz9（缺省 Q）。
- 静态默认：N=Letter 612×792pt、O=36pt 边距、P=72dpi、
  Q=tu1 色纸。
- `f1a` = {rvb 序源, cl2/oja/q07/kia 索引族}——bfj.b 锚点。

## Harmony 核对

物化态+SET_METADATA winner ↔ 寄存器组；Letter 默认 ↔
PageBackgroundModel/NoteTypes。

## 产出

- 证据：`phase-885-document-model.md`
- Fixture：`d02-document-model.mjs`（21/21）
- ADR-0829；全量 Replay 与双 HAP 结果记录于提交。
