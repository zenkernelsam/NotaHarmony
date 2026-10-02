# Phase 1458 修复报告 — RTL 左锚旋转柄

## 目标

结清 Phase 1450 登记的 RTL 差异：原版 `yj8` 布局方向驱动旋转柄
锚边翻转（RTL 茎锚左边中点并向左延出），Harmony 此前固定右锚。

## 原版证据

- `yj8.java`：`{F=Ltr, G=Rtl}`；`ms1` 容器方向注入命中分发。
- `gsf.i`：LTR→`sbe.c` 右边中点 / RTL→`sbe.a` 左边中点。
- `gsf.e`：茎 `56dp/zoom·(F?+1:−1)` 方向翻转。
- `ms1:525`：`vtf.e` startingRadians RTL +π 补偿。

## Harmony 实现

- `@State selectionRotateHandleRtl` ←
  `i18n.isRTL(i18n.System.getSystemLanguage()) === LayoutDirection.RTL`
  （`updateSelectionOverlay` 内同步）。
- `SelectionOverlay` `@Prop selectionRotateHandleRtl`：茎与端点圆
  按锚边镜像（`left−56`/`right+56`）。
- `selectionRotateHandleAt` 命中圆心同规则镜像。
- 起始角 +π 不显式实现——实测触点角天然自洽（左触点角≈π）。

## 验证

- `d02-original-selection-handle-geometry.mjs` 扩至 15 项全绿。
- 全量基线 + note@default + note@ohosTest 构建见提交说明。
