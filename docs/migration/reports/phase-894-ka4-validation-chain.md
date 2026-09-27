# Phase 894 报告 — `ka4`/`ddg` 校验链实名

## 范围

实名校验接口契约与页面/PDF/资产规则全集。纯审计。

## 原版发现

- `ka4.a()`：null=合法，错误串=非法（ybg.c 驱动）。
- `ln2`：pageCount≠0 + 等于 PDF pagesConsumed + 级联。
- `ddg.f(sw9)`：页数>0、消耗>0、cropBoxes=消耗数、
  消耗范围≤总数、逐框校验、wa0 级联。
- `wa0.a()`：size>0/mime 非空/name 非空。
- `ddg.g(nz9)`：PDF 需显式尺寸、边距≤页、基向旋转、
  qed/k3a 级联。

## Harmony 核对

编码侧 throw 门 + 创建检查逐条对齐。

## 产出

- 证据：`phase-894-ka4-validation-chain.md`
- Fixture：`d02-ka4-validation-chain.mjs`（19/19）
- ADR-0838；全量 Replay 767 文件绿。
