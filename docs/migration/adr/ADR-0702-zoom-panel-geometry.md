# ADR-0702：Zoom 面板原版几何——画布卡 272dp + 控制条内沿序交换

- 状态：Accepted（部分纠正 ADR-0700 的翻转机制结论）
- 日期：2026-09-25
- 关联：ADR-0695（面板落地）、ADR-0698（覆盖层）、ADR-0700（夹取域）、
  `phase-754-zoom-panel-geometry.md`

## 背景

Phase 754 复核 `fgg.b` 时发现两处与原版结构不符：

1. **画布卡高度**：原版 `njj.d` Surface 高 `272.0f`dp 且仅包 `dgg`
   画布卡；`wfg` 控制条为 Column 兄弟节点。Harmony Phase 747 取了
   160vp，无证据依据（缩水 41%）。
2. **顶停靠翻转机制**：原版 `fgg.b` 在 `cgg` Column 内按
   `dockEdge==qeg.I` 条件把 `fgg.a`（wfg 控制条）渲染于画布卡
   **之前或之后**——控制条恒贴面板内沿。ADR-0700 依据 `svf` 的
   `"toolboxFlip"` 动画名将其实现为 `scaleY=±1` 图标镜像；复核表明
   `svf` 的翻转作用于主工具条，Zoom 面板自身机制是 **Column 序交换**，
   镜像会倒置按钮字形，非原版。

## 决定

- `ZOOM_SURFACE_HEIGHT_VP`/`surfaceHeightVp` 取 **272**（vp 等价 dp，
  与全仓 dp→vp 约定一致）；源窗口高度由 `272/mag` 派生。
- 控制条与画布区抽为 `@Builder`，`build()` 按 `dockBottom` 交换
  Column 顺序：底停靠 `[bar][surface]`、顶停靠 `[surface][bar]`。
- 删除控制条 `scaleY` 镜像。

## 后果

- 面板高度、控制条停靠侧与原版逐一对齐；源窗口纵向视野随
  272/5=54.4 文档单位扩大（原 160/5=32）。
- ADR-0700 中关于 `panelInTopHalf`→图标镜像的机制结论被本 ADR
  纠正为 Column 序交换（`panelInTopHalf` 由 `egg` 布局流写入的
  登记不变）。
- 未复刻：`l96.J` AnimatedVisibility 500ms 滑入滑出、`z5c.H`
  拖拽中逐像素跟随——保持近似登记（落点判定），均已在
  ADR-0695/0700 近似清单中。

## 验证

- `d02-original-zoom-view.mjs`：h160→h272 演进、p752.chromeflip.scale
  钉撤除、+6 p754 钉；专项与全量套件见提交。
- `note@default` / `note@ohosTest` HAP 构建通过。
