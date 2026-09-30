# Phase 1302 报告 — 手写转文本/数学

## 完成内容

- `dhb`（18137 行最大业务类）= 手写→数学/文本转换
  （`showMath`/`showTextConversionFailure` 失败 UI+
  "selection spans pages" 跨页校验+`Math.abs` 笔画几何
  分析+结果应用回调）—— MyScript iink 集成（选区笔迹
  →LaTeX 数学/文本→页面替换）；引擎不可移植但转换
  UI/校验可移植。

## 产出

- evidence `phase-1302-handwriting-conversion.md`
- fixture `d02-handwriting-conversion.mjs`（10/10）
- ADR-1246
