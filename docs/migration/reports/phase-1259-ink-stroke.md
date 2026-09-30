# Phase 1259 报告 — 墨笔迹模型

## 完成内容

- `ka8`=笔迹渲染模型 `{Path,List,i5g,Path,Float}`；
- `i5g`=InkStyle `{color,size,t16 tool,bool×2}`；
- `t16`=InkStyle 枚举（VARIABLE_WIDTH/FIXED_WIDTH/
  DASH/DOTS）；`nfe`/`ofe`=Path 工厂 —— 墨笔迹模型。

## 产出

- evidence `phase-1259-ink-stroke.md`
- fixture `d02-ink-stroke.mjs`（10/10）
- ADR-1203
