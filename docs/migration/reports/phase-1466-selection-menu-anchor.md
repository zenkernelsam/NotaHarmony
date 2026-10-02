# Phase 1466 报告：选区动作菜单侧锚定位（i3b 弹层位置提供器）

## 原版行为（1.4.2 证据）

`ShowSelectionMenu` 意图 `y3b(sbe, msf)` → 消费端 `mnm.c`：

- `mfc.n(sbe)`：选区 sbe 轴对齐矩形 × `k()` 缩放 − 画布原点 =
  屏 px `ku7` 锚框；
- `odf.c(ku7, 72, 72)`：四边膨胀 **72 屏 px**（= 旋转柄茎 56 +
  端点 16 触及区清除）；
- `abn.e → abn.c`：去 `WindowInsets + 12dp` 后交 `i3b` 定位；
- `i3b`（PopupPositionProvider）：LTR `x = 锚框右缘 + margin`，
  溢出 → 左缘 `a − W − margin`，仍溢出 → 容器右缘夹取；RTL 镜像；
  `y = odf.a 锚框中心y − 菜单高/2` 夹取容器——**菜单面板贴选区
  侧缘、纵向居中**。

## Harmony 缺口（P1461 登记）

`selectionOverlayPosition`：`x = rect.left` 夹取（左对齐）、
`y = rect.bottom + 8`（下挂）——与原版「侧置 + 纵向居中 +
旋转柄区清除」语义不符；旋转选区的柄会伸入菜单区。

## 实现

`selectionOverlayPosition(rect, cw, ch, hasPaste, rtl)` 重写：
`inflate = px2vp(72)`；LTR 右缘优先、溢出左缘、再溢出右缘夹取；
RTL 镜像；纵向锚框中心 − 组高/2 夹取。`SelectionOverlay` 按钮与
`isInSelectionMenu` 命中共用此函数，RTL 复用
`selectionRotateHandleRtl`。

## 验证

- 新 fixture `d02-original-selection-menu-anchor.mjs`：14 项
  （含 i3b 裁决可执行模型：右置/左回退/右缘夹取/RTL 双侧/
  纵向居中夹取）。
- `note@default` 构建通过；全量 Replay 与 `note@ohosTest` 收尾
  验证。

## 遗留差异

- 按钮+下拉结构维持 T-033 ArkUI 适配（原版为整列弹层面板）；
  本 Phase 仅对齐锚点。
- 窗口 insets 与 12dp 内边距未复刻（互相抵消后残余 ≤ 边缘 vp
  级），登记。
