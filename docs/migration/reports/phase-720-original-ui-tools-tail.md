# Phase 720：`ui_tools__` 族尾部收口

`ui_tools__*`（45 键）审计收尾：工具名/激光尾/橡皮模式/取色/
录音控制/胶带操作此前已移植，尾部 2 项落地 + 3 项边界登记。

## 原版证据

- `yed.java` ×4：`ui_tools__width`="Width: %1$d" 宽度滑块读数
  （Harmony 原为 `'Width: '+N` 字面量）。
- `jfh.java:39-53`：选区 Box/Free 双模式图标各挂
  "Rectangle/Freehand selection" a11y。
- `rz1.q()`/`a6f`/`y5f`/`x82.r`：默认工具箱含 MEDIA(6)/RECORD(7)
  画布工具（x4f/e5f 态）——Harmony 无画布工具激活面，同名能力经
  工具栏加项菜单+录音面板交付 → 边界登记。
- `hx1` STROKE/FILL 页签、`r22` no_fill、`o4j` color_options、
  `rw1` recents 图标——形状属性 sheet/对应 a11y 节点未移植 →
  登记；POINTER/RULER/ZOOM 已随早前登记覆盖。

## 实现

- `WidthSlider`：`'Width: '+N` 字面量 → `$r('app.string.ui_tools_width',
  Math.round(v))`（对齐原版整型入参）。
- 选区模式钮：`.accessibilityText` 挂当前模式的
  select_rect_mode/select_freehand_mode（单切换形态保留）。
- 新串 ×3 双 locale。

## 验证

- `d02-original-ui-tools-tail.mjs`（12 断言：yed 四渲染位/jfh 四键/
  rz1 默认集/x82 映射/hx1 页签 + 资源化/round/a11y/双 locale）。
- `ui_tools__*` 族全量审计完毕（ADR-0668）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
