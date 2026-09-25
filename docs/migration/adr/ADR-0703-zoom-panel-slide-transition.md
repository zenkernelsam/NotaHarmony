# ADR-0703：Zoom 面板 AnimatedVisibility 靠缘 slide+fade 过渡

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0695（面板落地）、ADR-0702（几何/序交换）、
  `phase-755-zoom-panel-slide-transition.md`

## 背景

`fgg.b` 以 `l96.J`（AnimatedVisibility）包裹 Zoom 面板：
`ey3.c/j` slide+fade 组合进出、`s01.Y(500,0,cs3.a)` 500ms tween、
插值器 `iq2(0.25,0.1,0.25,1)`（标准 ease）、滑入缘随停靠侧
（`is1.S/U` = Top/Bottom）。Harmony Phase 747 的 `if` 挂载为瞬时显隐。

## 决定

挂载 Column 追加 `.transition(TransitionEffect.move(edge)
.combine(TransitionEffect.OPACITY).animation({500, Curve.Ease}))`：

- `Curve.Ease` 三次贝塞尔 (0.25,0.1,0.25,1) 与 `cs3.a` 精确一致；
- `TransitionEdge.BOTTOM/TOP` 映射 `is1.U/S` 停靠缘；
- `.combine(OPACITY)` 对应 slide∘fade 组合。

## 后果

- 面板激活/关闭时按原版方向+时长+缓动滑动淡入/淡出；
  Close/换工具回落走同一过渡。
- 拖拽中连续位移动画仍属落点判定近似（ADR-0695 登记不变）。

## 验证

- `d02-original-zoom-view.mjs` +4 p755 钉（transition.move/combine/
  duration/ease + 文档钉）；专项与全量见提交。
- `note@default`/`note@ohosTest` HAP 构建通过。
