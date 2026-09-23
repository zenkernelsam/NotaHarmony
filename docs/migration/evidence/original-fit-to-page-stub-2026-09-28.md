# 证据：原版选区菜单 FIT_TO_PAGE 是上游死项（dhb case15）

- 日期：2026-09-28；Phase 633
- 原版来源：`decompiled_1.0.3/sources/defpackage/dsc.java`、
  `ux9.java`、`dhb.java`
- Harmony 实现：`note/src/main/ets/ui/components/SelectionOverlay.ets`

## 原版事实

- `dsc` 枚举 ordinal 15 = `FIT_TO_PAGE`（dsc.java:
  `new dsc("FIT_TO_PAGE", 15)`），`ux9` case15 正常渲染菜单项
  （icon + `selection_menu_fit_to_page` 文案，ux9.java:1813-1816）。
- 但分发处理器 `dhb` 的 case15 方法体仅为
  `throw new NotImplementedError(0)`（dhb.java:17986）——
  原版该菜单项点击即抛未实现异常。两侧 case20（DESELECT）
  与 case21（MORE）均为真实实现，仅 15 是桩。

## 结论

FIT_TO_PAGE 在原版 1.0.3 中是**渲染但不可用的死按钮**。
Harmony 的省略不是移植缺口，而是对上游未交付项的正确省略——
且比原版行为更严（原版点击崩溃/抛错，Harmony 不展示死项）。

## 登记更新

- `SelectionOverlay.ets` 菜单注释补注 `*原版 dhb case15 即
  throw NotImplementedError`。
- `original-selection-menu-order-harmony-2026-09-22.md`
  差异登记中 FIT_TO_PAGE 由"无对应实现——登记"升级为
  "上游死项——省略即 parity"。
