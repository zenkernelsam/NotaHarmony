# ADR-1393：RTL 布局左锚旋转柄（yj8.G）

- 状态：已采纳
- Phase：1458（结清 Phase 1450 登记差异）

## 背景

Phase 1450 移植 `gsf.e/b` 手柄几何时将旋转柄固定于右边中点，
RTL 左锚登记为差异。本 Phase 用 `yj8` 布局方向枚举补齐。

## 原版语义（证据见 phase-1458-rtl-rotate-handle.md）

- `yj8 = {F:Ltr, G:Rtl}`，由 `ms1.H` 容器布局方向注入。
- `gsf.i`：LTR 锚 `sbe.c`（右边中点），RTL 锚 `sbe.a`（左边中点）。
- `gsf.e`：茎 `f3 = 56dp/zoom · (F ? +1 : −1)` —— RTL 向左延。
- `ms1:468-480` 命中域随锚边镜像；`ms1:525` `vtf.e` 起始角 RTL +π。

## 决策

- Harmony `@State selectionRotateHandleRtl` ←
  `this.getUIContext().i18n.isRTL(getSystemLanguage)`，
  在 `updateSelectionOverlay` 镜像（方向切换即时生效）。
- `SelectionOverlay` 新增 `@Prop selectionRotateHandleRtl`：
  茎 Rect 锚 `left−56`/`right`，端点双层圆同侧镜像。
- `selectionRotateHandleAt` 命中圆心按锚边取 `left−STEM`/`right+STEM`。
- `vtf.e +π` 不显式移植：Harmony `resizeStartAngle` 取按下实测
  触点角，左侧触点天然 ≈π，起始增量自洽为零。

## 验证

- `d02-original-selection-handle-geometry.mjs` 扩至 15 项（RTL prop、
  状态驱动、命中镜像、prop 接线）全绿。
