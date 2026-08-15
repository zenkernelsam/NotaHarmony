# ADR-0216：Shape partial erase 必须按原生 Path 裁切并物化为 Ink

## 状态

Accepted，2026-08-15。扩展 ADR-0214 与 ADR-0215。

## 问题

前两阶段只闭环普通 Ink 的实体替换和 Group member 更新。Shape 在 partial eraser 中仍完全缺席；若直接复用
`ShapeGeometry.shapeLocalSubpaths()`，ELLIPSE 与二次/三次 LINE 会先被采样成折线，箭头主线还会提前截短，
与原版 `q16.e/xai.d/o1.shapeErasePaths` 的 Android `Path` 语义不一致。普通 `EraserEngine` 还会把中心线
擦除半径扩大半个 border width，导致只擦到 Shape 边缘时中心线也被错误切断。

## 原版证据

详见 `docs/migration/evidence/original-shape-partial-erase-jadx-2026-08-15.md`：

1. `xai.d()` 对 LINE 使用原生 `lineTo/quadTo/cubicTo`，对 ELLIPSE 使用 `addOval`，POLYGON 使用闭合
   line path；
2. `o1.shapeErasePaths` 的 center 是完整 Shape path，`l96.W()` 只额外提供 arrowhead path；
3. `n8j.d()` 把 eraser 逆变换到 Shape 局部坐标，不把 center clipping 半径扩大 border width；
4. `n8j.e()` 分别裁切 center、由 center+width+arrow 生成的 custom outline，以及仅在有 fill color 时存在的
   fill path；
5. `o8j.a/u5j.g` 把每个 retained component 写成 CREATE_INK fields 9/10/11 的
   center/custom/fill，field 12 是 nullable fill color；失败为 Unchanged，空结果为完整删除。

## 决策

1. 新增 `OriginalShapePartialEraser`，使用 Harmony `drawing.Path`、`Pen.getFillPath()` 与
   `Path.op(DIFFERENCE/INTERSECT/UNION)` 在 Shape 局部坐标执行裁切。
2. Shape center path 按原版构造：
   - LINE：保留 line/quadratic/cubic verb；
   - ELLIPSE：使用 `addOval(..., start=right, CLOCKWISE)`；
   - POLYGON：逐点 line，并按闭合状态 close；
   - SINGLE arrow 依据 `d1j/l96.W` 的宽度分段公式生成额外 triangle，不截短擦除 center path。
3. outline 一律从完整 center path 与 Shape border width 生成，再 union arrowhead；fill 仅在非 LINE 且
   `fillColor != null` 时存在。center、outline、fill 各自 difference eraser，随后按可见 component 重新归属。
4. center clipping 使用 `Path.getLength/getPositionAndTangent/getSegment`，只测试点是否位于局部 eraser
   fill 内；边界二分 20 次。曲线 segment 继续以 cubic 写入 CREATE_INK，而非重建为采样直线。
5. Harmony PathIterator 暴露 CONIC verb 但不暴露 rational weight。遇到 oval/conic 时，boolean 与 clipping
   仍使用原生 Path；只有最终无法直接编码 conic 的 CREATE_INK center/custom/fill path 以误差 `0.05`
   自适应近似，不把 conic 错当 weight=1 quadratic。多 contour 的同 fraction 断点继续恢复为独立 MOVE。
6. 最多采样 131,072 个 center positions。超过预算、奇异 transform、Path op/iterator/segment 失败均返回
   Unchanged，禁止把无法证明的裁切降级为删除。
7. Shape remnant 继承 source transform、z-index、tool/style/color/fill、Pencil seed、Dash/Dots phase 与 Tape/
   Highlighter 标记；custom/fill auxiliary path 保留多 MOVE component 和曲线 verb。
8. `OriginalPartialEraseReplacementPlan` 泛化为显式 `sourceKind: STROKE | SHAPE`。持久提交、本地 fallback、
   mixed element order、Group replacement 与 Undo/Redo 都允许 Shape source，但所有 remnant 仍严格是 Ink。
9. CREATE_INK encoder仅在 auxiliary path/fill 存在时使用完整 20-field table；旧 compact layout 保持
   byte-stable。

## 结果

- 同一 partial-erasure gesture 可以混合裁切普通 Ink 与 Shape，并按原页面 element order 统一提交。
- Ellipse 和曲线 Line 的 outline/fill clipping 不再退化成固定分段折线；箭头只擦到 wing 时完整 center 不会
  被错误缩到 arrow base。
- 只碰到宽 border 边缘时，custom outline 会产生缺口，但 center path 不会因额外半笔宽而被过度裁切。
- 原版 `xai.d()` 对 POLYGON 一律闭合；Harmony legacy `isClosed=false` 不再把 closing edge 从擦除几何漏掉。
- Shape source 在 original transaction、transaction-failure fallback、Group、Undo/Redo 与 restart history
  中都保持同一实体替换语义。

## 边界

- 未启动设备、模拟器、虚拟机或 Hypium；ArkGraphics2D boolean 的像素边界和 CONIC iterator 行为仍需真机
  覆盖。
- 原版 transient partial-eraser preview/end 协议尚未完整闭环。
- ShapeCanvasRenderer 本身仍有独立的采样渲染历史债；本 ADR 修复的是 partial erase 几何与持久化结果，
  不宣称已完成整个 Shape renderer 的原生曲线重构。
