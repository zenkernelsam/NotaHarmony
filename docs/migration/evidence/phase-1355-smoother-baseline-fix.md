# Phase 1355 证据 — ForceSmoother 基线归属更正

**更正 Phase 1325**：`dr4`/`hr4` 引为平滑器基线误标。
实读：`hr4`/`dr4`/`fr4`/`jr4` = **文本标题样式枚举**。

## 真实内容

```
hr4 = enum-like（Enum.valueOf(hr4.class, str)；
  fr4 fr4Var = new fr4("Heading3", 3, true, 18.0f) ——
  Heading 样式枚举，字号 18.0f）
dr4 extends hr4 —— 标题样式枚举项
jr4 —— 枚举接口
```

→ `hr4`/`dr4` = 标题样式枚举（Heading1/2/3 字号），
非笔画平滑器。

## 更正说明

原版真实笔画平滑器（EMA/Kalman 类）在混淆源码中未
按命名定位 —— 此前的 `ms1`（float 对，正确）与 `dr4`
（标题枚举，误标）并存。Harmony `ForceSmoother`（8ms
EMA+0.15 maxChange 钳制）实现为文档化近似，其
`ws4`/`dr4` 引用中 `dr4` 误标（实为标题枚举）。

## Harmony 决策

ForceSmoother 基线归属更正；`dr4`/`hr4` 实为标题样式
枚举。算法实现保留（文档化近似），引用标注更正。

## 产出

- fixture `d02-smoother-baseline-fix.mjs`（10 断言）。
- ADR-1296；中文报告。
