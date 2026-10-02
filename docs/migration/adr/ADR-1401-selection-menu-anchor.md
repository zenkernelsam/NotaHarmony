# ADR-1401: 选区动作菜单锚 = 膨胀选区矩形侧向居中（i3b 移植）

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1466
- **关联**: evidence/phase-1466-selection-menu-anchor.md
  （`mnm.c`/`abn.e`/`i3b`/`odf.c`/`mfc.n` 解码）

## 背景

原版选区菜单经 `y3b(sbe, msf)` → `mfc.n(sbe)` 屏矩形
`odf.c(·,72,72)` 膨胀 72px → `i3b` 弹层定位：LTR 先锚框**右侧**、
溢出回退左侧、再溢出右缘夹取；纵向 = 锚框中心 − 菜单高/2。
Harmony 此前把菜单按钮放在选区左下（左对齐+下挂 8vp），旋转
选区的旋转柄伸出右侧时会与菜单碰撞（P1461 登记差异）。

## 决策

`selectionOverlayPosition` 重写为 i3b 语义：

- `inflate = px2vp(72)`（`odf.c` 72 屏 px → vp）；
- 主侧 = `rect.right + inflate`（LTR）/`rect.left − inflate − W`
  （RTL），溢出依次回退对侧与容器缘夹取；
- 纵向 = 锚框中心 − 组高/2 夹取容器；
- RTL 复用 `selectionRotateHandleRtl`（`yj8` 等价通道）；
- `isInSelectionMenu` 命中测试共用同一布局函数。

## 等价性与边界

- Harmony 菜单仍为「按钮 + bindMenu 下拉」（T-033 登记适配），
  本决策对齐按钮锚点到原版弹层面板位置。
- 窗口 insets、12dp 容器内边距未逐点复刻（Harmony 覆盖层全屏
  无 insets 概念；净效应为原版中的 ±12dp 偏移互相抵消，差异
  仅余边缘几 vp）。
- 原版膨胀用屏 px（72px ≈ 24vp @3x）；`px2vp` 运行时换算保持
  设备无关。

## 后果

菜单按钮贴选区右侧、垂直居中、避开旋转柄区；RTL 镜像；
`d02-original-selection-menu-anchor.mjs` 14 项断言。
