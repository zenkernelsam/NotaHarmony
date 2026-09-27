# ADR-0879 — 注释锚点多态 + oz9/op 细节

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `im`=AnchorKind{NONE,CANVAS,TEXT,ENTITY,REPLY}
  → `z5c.t` 分发 hd1/lhe/my3/cwb（两个 inline
  结构 + 两个间接表）。
- `oz9`=BookmarkState{UNBOOKMARKED,BOOKMARKED}。
- 注释/字段 op：tl2 CreateComment（im@0+锚@1）、
  ud8 ModifyComment{comment,anchor,text,resolved}、
  ra0 AssetCloudPersisted{assetHash}、
  ee8 ModifyPDFField{assetHash,key,valueType,
  valueString,valueBoolean}、mqf UpdateCheckbox。

## Harmony 决策

锚多态分发对齐；未知序数失败关闭。

## Parity 状态

等价。

## 验证

- `d02-anchors-comments.mjs`：13/13 通过。
- 全量 Replay 808 文件绿，见 Phase 935 提交。
