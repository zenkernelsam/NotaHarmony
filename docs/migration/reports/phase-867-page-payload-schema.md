# Phase 867 报告 — 页面 payload 模式登记

## 范围

登记 CREATE_PAGE/MODIFY_PAGE payload 模式：`ln2`/`nz9`/`sw9`
三表 + `vy7`/`qed`/`mmf`/`k3a` 子结构；核对 Harmony CreatePage
写手。纯审计阶段，无源改动。

## 原版发现

- `ln2`：f0=cxc 位置、f1=nz9 外观、f2=pageInAsset（默认 1）、
  f3=oz9 bookmark（byte 安全解码，越界回退 UNBOOKMARKED）。
- `nz9`：k3a 背景 + sw9 PDF-in-asset + float + qed + vy7。
- `sw9`：wa0 资产 + xw9 范围 + qed 页尺寸向量 + `n()` 总页数。
- `mmf` = inline int 值类；`k3a` 含 hu1/n3a/Boolean×2。

## Harmony 核对

`OriginalCreatePagePayloadEncoder` 逐项等价 ln2 写手（vtable
字段序+cxc 布局）；外观模型由 DefaultTemplate/PageBackgroundModel
承载。nz9/sw9 深层字段已登记备查。

## 产出

- 证据：`phase-867-page-payload-schema.md`
- Fixture：`d02-page-payload-schema.mjs`（24/24）
- ADR-0811；全量 Replay 与双 HAP 结果记录于提交。
