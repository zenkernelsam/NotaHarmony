# Phase 633 报告：原版 FIT_TO_PAGE 上游死项核实

- 日期：2026-09-28
- 证据：`docs/migration/evidence/original-fit-to-page-stub-2026-09-28.md`
- 性质：证据收口（上游桩核实），无行为变更

## 背景

`original-selection-menu-order` 证据把选区菜单 FIT_TO_PAGE
（dsc ordinal 15）登记为"整页适配无对应实现"的省略项。

## 复核结论

原版 `ux9` case15 正常渲染菜单项，但分发器 `dhb` case15 的
方法体仅为 `throw new NotImplementedError(0)`
（dhb.java:17986）——原版该按钮是渲染而不可用的死项。
同分发器 case20（DESELECT）/case21（MORE）均为真实实现，
仅 15 是桩。

Harmony 不展示 FIT_TO_PAGE 不是移植缺口，而是对上游未交付
项的正确省略——且严格优于原版（原版点击抛错）。

## 变更

- `SelectionOverlay.ets`：菜单注释补注上游桩证据。
- `original-selection-menu-order` 证据差异登记：FIT_TO_PAGE
  由"无对应实现"升级为"上游死项——省略即 parity"。
- `d02-original-selection-menu-order` 回放新增 3 断言：
  dhb case15 保持 NotImplementedError、Harmony 不暴露
  FIT_TO_PAGE 动作、注释引用桩证据。

## 验证

专项 49/49 全绿；全量回放与双 HAP 构建见本节验收记录。
