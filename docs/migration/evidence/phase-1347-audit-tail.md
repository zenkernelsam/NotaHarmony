# Phase 1347 证据 — 审计收尾（选区 overlay + 缩略图）

来源：`ui/components/SelectionOverlayLayout.ets`+
`rendering/ThumbnailRenderPolicy.ets` —— 最后两个未
逐文件审计的文件。

## `SelectionOverlayLayout`

```
// 原版 msc.c selectionHasRotationHandle：旋转柄悬于
//   顶边中点上方
selectionOverlayPosition(rect, containerWidth, ...)
standalonePastePosition(containerWidth)
```

→ 选区 overlay 定位（旋转柄顶边中点上方）+粘贴按钮
定位 —— 对照 `msc.c` 选区 overlay 布局语义。

## `ThumbnailRenderPolicy`

```
fitPageInThumbnail(pageW,pageH,thumbW,thumbH,margin):
  校验有限+正尺寸+margin 合法
  scale = min((thumbW-2m)/pageW, (thumbH-2m)/pageH)
  —— 等比适配（letterbox），居中
```

→ 缩略图 = 等比 letterbox 适配（含 margin）—— 页预览
缩略图几何。

## 审计覆盖完成度

至此 `note/src/main/ets/` 下 **9 顶层目录全部文件**已有
对应 evidence/phase 审计（data 157 + core 77 + rendering
22 + ui 31 + abilities 13 + pages 1 ≈ 300 文件）。

## Harmony 决策

选区 overlay= `msc.c` 旋转柄语义；缩略图=等比 letterbox
—— 100% 文件级审计覆盖达成。

## 产出

- fixture `d02-audit-tail.mjs`（10 断言）。
- ADR-1289；中文报告。
