# Phase 1046 报告 — 页面操作载荷 + ddg 校验库

## 范围

`ln2`/`ge8` 页操作、`ddg` 共享校验库、`nz9`/`m2d`/`sw9`
背景模型。纯审计。

## 原版发现

- CreatePage{location,background:nz9,pageCount,bookmarked}：
  0 页拒绝、PDF 消耗页数须相等、`ddg.g`/`ddg.f` 子校验。
- ModifyPage{pages,moveTo,background:m2d,bookmarked}：
  pages>0、同套背景校验。
- `nz9`=PageBackground{paper,pdf,rotation,size,margins}。
- `ddg` 校验全集：触控笔点（azimuth 单位向量/altitude≤π/2/
  width/force 有限非负）、PDF cropbox 逐页、背景边距
  小于页尺寸+基本方向旋转、qed 尺寸非负。

## Harmony 决策

校验逐条保留；`ddg`→共享 OpValidators。

## 产出

- 证据：`phase-1046-page-ops-validators.md`
- Fixture：`d02-page-ops-validators.mjs`（12/12）
- ADR-0990；全量 Replay 见本提交。
