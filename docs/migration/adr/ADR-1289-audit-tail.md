# ADR-1289：审计收尾（100% 文件覆盖）

## 状态

已接受（Phase 1347）。

## 决策

选区 overlay=`msc.c` 旋转柄顶边中点语义；缩略图=等比
letterbox —— 达成 100% 文件级审计覆盖。

## 理由

`SelectionOverlayLayout`（`selectionOverlayPosition`/
`standalonePastePosition`，对照 `msc.c` rotation-handle
布局）+`ThumbnailRenderPolicy`（`fitPageInThumbnail` 等比
letterbox+margin）—— 至此 `note/src/main/ets/` 全 9 顶层
目录所有文件均有对应审计 evidence。

## 后果

**100% 文件级审计覆盖达成** —— 无未审计源文件。
