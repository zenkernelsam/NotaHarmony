# Phase 928 报告 — 叶结构闭合 + zgb/ww9

## 范围

叶结构布局与线型尾表实名。纯审计。

## 原版发现

- fqa=Point{x@0,y@4}、qed=Size{w@0,h@4} 自然序；
  hd1=CanvasAnchor、my3=EntityAnchor 评论锚点型别；
  zgb=ReceiveOpsEvent 服务端下发批量；
  ww9=PDFField valueType{STRING,BOOLEAN}。

## Harmony 核对

布局/事件/枚举对齐。

## 产出

- 证据：`phase-928-leaf-closure.md`
- Fixture：`d02-leaf-closure.mjs`（11/11）
- ADR-0872；全量 Replay 801 文件绿。
