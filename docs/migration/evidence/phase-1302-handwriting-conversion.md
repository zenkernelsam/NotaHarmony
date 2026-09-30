# Phase 1302 证据 — 手写转文本/数学（MyScript 转换集成）

来源：`defpackage/dhb.java`（18137 行，最大业务类）。

## `dhb implements ix4` = 手写转换控制器

- `showMathConversionFailure`/`showTextConversionFailure`
  —— 数学/文本转换失败 UI。
- `"Math conversion selection spans pages"` —— 选区不能
  跨页校验（`a.c(yn7Var, ...)`）。
- `Math.abs(fArr[i]-fValueOf)` —— 笔画几何/空间分析
  （选区内 stroke 框选判定）。
- `wx4Var.invoke(bq0Var.c, list.get(...))` —— 转换结果
  应用回调。

## 语义

**手写→数学/文本转换** —— 用户框选笔迹 → MyScript
iink 识别 → LaTeX 数学公式 / 文本 → 替换到页面 —
— 失败提示+跨页校验+几何分析。

## Harmony 决策

MyScript iink 不可用 → 失败关闭（ADR-1168）；转换
UI/选区校验/几何分析 → Harmony 可移植（选区逻辑+
失败提示保留）；识别引擎 → 需替代（Harmony 手写识别
或 fail-closed）。

## 产出

- fixture `d02-handwriting-conversion.mjs`（10 断言）。
- ADR-1246；中文报告。
