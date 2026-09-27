# ADR-0872 — 叶结构闭合 + zgb/ww9

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 叶结构布局：fqa=Point{x@0,y@4}、qed=Size
  {width@0,height@4}（自然序）、hd1=CanvasAnchor、
  hu1=Color 4B、cxc 12B、qo5 8B、utf 16B、ua0 64B。
- `my3` = EntityAnchor{qo5[]}；`zgb` =
  ReceiveOpsEvent{ops,expectedAckReply,schemaVersion}
  服务端下发批量；`ww9` = PDFField valueType
  {STRING,BOOLEAN}。

## Harmony 决策

点/尺寸自然序布局对齐；收包事件与 PDF 值型
枚举对齐。

## Parity 状态

等价（线层叶结构全闭）。

## 验证

- `d02-leaf-closure.mjs`：11/11 通过。
- 全量 Replay 801 文件绿，见 Phase 928 提交。
