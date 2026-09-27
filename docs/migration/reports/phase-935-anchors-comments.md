# Phase 935 报告 — 锚点多态 + 注释/字段 op 细节

## 范围

`z5c.t` 锚分发 + oz9 + 五 op 实名。纯审计。

## 原版发现

- im=AnchorKind 5 值→z5c.t 分发：hd1 Canvas
  (inline)/lhe TextAnchor{textField,selection}/
  my3 EntityAnchor{entities}/cwb ReplyAnchor{root}。
- oz9=BookmarkState{UNBOOKMARKED,BOOKMARKED}。
- tl2/ud8/ra0/ee8/mqf 字段实名确认。

## 产出

- 证据：`phase-935-anchors-comments.md`
- Fixture：`d02-anchors-comments.mjs`（13/13）
- ADR-0879；全量 Replay 808 文件绿。
