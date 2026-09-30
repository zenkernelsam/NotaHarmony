# Phase 1176 报告 — 墨迹笔画模型

## 完成内容

- `t16`=`InkStyle` 枚举坐实（VARIABLE_WIDTH/FIXED/DASH/
  DOTS）；`i5g` 样式 `{色,宽,InkStyle}`；`ka8` 笔画
  `{2×Path,points,style,width}` —— 墨迹渲染管线。

## 产出

- evidence `phase-1176-ink-stroke.md`
- fixture `d02-ink-stroke.mjs`（10/10）
- ADR-1120
