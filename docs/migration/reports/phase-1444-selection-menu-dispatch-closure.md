# Phase 1444 — sqf 菜单分发侧审计收口（urf 菜单轴终局之二）

## 范围

1.4.2 `sqf`（wqf.ordinal() 23-case 分发器）逐支对照 Harmony
`onSelectionMenuAction`——继 Phase 1442 装配侧收口后的分发侧终局审计。

## 原版证据

- `sqf.java` switch 全 case 解码（STYLE/COPY/CUT/DUP/GROUP/UNGROUP/
  SEND_×4/DELETE/CONVERT_×2/EDIT_MATH/STICKER/CROP/FIT_TO_PAGE/
  FLIP_×2/LOCK|UNLOCK/DESELECT/MORE）。
- `ome.a()`=`hmb.g(null)`=清选区状态流——原版动作后清选区语义。
- `urfVar.I` CONVERT 确认流（ms6/ls6/ks6 三支）。
- `urfVar.H()` EDIT_MATH 面板态转移（lrf.a）。

## 结论

23 case 全部对齐或登记 fail-closed，**无代码变更**；
证据/注释/fixture 固化（ADR-1379）。

## 验证

- `d02-selection-menu-dispatch-closure.mjs`：11/11。
- 全量基线 + `note@default` / clean `note@ohosTest`：见提交记录。
