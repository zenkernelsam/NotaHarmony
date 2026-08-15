# ADR-0217：Ink partial erase 必须保留原版 center/custom/fill 与 Pencil 状态

## 状态

Accepted，2026-08-15。扩展 ADR-0214、ADR-0215 与 ADR-0216。

## 问题

Phase 237 的普通 Ink replacement 仍以旧 `EraserEngine` 中心线分段为几何来源：它扩大半个笔宽后裁 center，
丢失 native cubic、显式 custom/fill、Pencil，以及原版在裁切边界推进的 Pencil seed/reference 和 Dash/Dots
phase。Phase 239 已为 Shape 建立 `n8j/o8j` 风格 Path 管线，但既有 Ink 尚未接入。

若只把 Pencil 加回旧分段器，会出现三类持久错误：视觉缺口与原版不同；重载后 splat 随机序列跳变；
fill-only/custom-only component 被静默丢弃。奇异矩阵或 PathOp 失败后若继续提交，还会把“无法证明”误当完整删除。

## 原版证据

详见 `docs/migration/evidence/original-ink-partial-erase-jadx-2026-08-15.md`：

1. `jt1` 从 Ink 独立读取 center/custom/fill，并将 eraser 逆变换到 Ink 局部坐标；
2. `n8j.e()` 仅在 custom 缺席时生成 outline，fill 仅在 fill color 存在时启用，center 不扩大半笔宽；
3. `o1/ft1/cfa` 规定 Pencil outline 为 `2.84 × baseWidth`，style supplier 用 base width 推进 seed/reference；
4. Dash/Dots 在裁切距离处推进 phase，并只保留源 period；
5. `n8j/o8j` 物化每个可见 component，包括 fill-only component；
6. `o8j` 按 retained center 距离重算 AudioLinked 时间；失败为 Unchanged。

## 决策

1. 新增 `OriginalInkPartialEraser`，用 ArkGraphics2D `drawing.Path`、`Pen.getFillPath()` 和
   `Path.op(DIFFERENCE/INTERSECT/UNION)` 在 Ink 局部坐标裁切。
2. center 使用 `Path.getLength/getPositionAndTangent/getSegment`，只以 eraser fill 判断删除；边界二分 20 次，
   line/quad/cubic 最终统一保留为 CREATE_INK cubic segments。
3. explicit custom path 优先；缺席时从 attributed center 生成 outline。Pencil 的 base outline width 乘 `2.84`，
   路径 widthFactor 继续参与宽度；单点/零长度 Ink 生成 round circle。
4. fill 仅在 `fillColor != null` 且存在 fill path 时参与。center/custom/fill 分别 difference，再按 union 后的
   可见 component 重新归属；fill-only component用空 custom sentinel 适配当前 canonical center-path 模型，
   且必须支持再次擦除。
5. `PencilSplatGenerator` 新增 `generateWithState()`，暴露最终 seed、最后 emitted splat reference 与 emitted
   状态。每个 Pencil remnant 从源 seed/reference 对 center prefix 重放，再以边界状态生成本 component splats。
6. 裁切后的 Dash/Dots style-map 使用 `sourcePhase + startDistance mod period`；Pencil 字段置零，只保留源 period。
   未切 center 的 component复制源 entry；非 pattern 被切 component省略全零 style-map。
7. AudioLinked 根据 remnant center 的 `[startDistance,endDistance] / totalDistance` 重算 start/duration；
   fill-only component保留完整区间。
8. `StrokeCanvasPainter` 对 Pencil remnant 先以 explicit custom path clip，再绘制 splats，避免重建 splats越过
   boolean clipping 边界。
9. `NoteCanvasView` 的 PARTIAL 模式改用新裁切器；原 `EraserEngine` 继续只负责 whole-object 模式。
   `validateOriginalPartialErasePlan()` 允许 Pencil source，持久 transaction、Group、Undo/Redo 与 mixed order
   继续复用既有 Phase 237–239 管线。
10. 超过 center/component/path/splat 预算、奇异 transform、Path conversion/boolean/segment/style 失败全部返回
    Unchanged；禁止生成删除 source 的 replacement plan。
11. 本地 snapshot fallback 在改动元素、Group 或 history 之前，必须对全部 remnant 执行同一 CREATE_INK
    materialization preflight。canonical preflight 失败不能被误解释为“改走本地删除”；即使 source 是本地 ID，
    任一 remnant 无法编码时整次手势仍为 Unchanged。

## 结果

- Fixed/Variable/Dash/Dots/Pencil 与已有 custom/fill Ink 进入同一原版式 partial erase 几何管线。
- 只擦到宽 outline 边缘时 center 不再被半笔宽过度切断；native cubic 与边界 width/force/tilt 属性继续保留。
- Pencil remnant 重载后 seed/reference 与 splats稳定，`2.84` outline 和 attributed width 同时生效。
- fill-only component不会丢失，并可在后续手势继续擦除。
- 无法物化的 effects/path/style/transform remnant 不会经 fallback 删除源 Ink。
- transformed Ink、AudioLinked、effects、Tape、Highlighter、style、Group、z-order 与 persistent history 保持既有
  transaction 语义。

## 边界

- 未启动设备、模拟器、虚拟机或 Hypium；PathOp 边界、非均匀 transform 与 Pencil texture clip 仍需真机验收。
- 当前 center model 只支持一个 canonical component；当一个 visual component包含多个 center run 时，
  Pencil/Dash/Dots 会拆成多个 remnant。Fixed/Variable 由 explicit custom path 保持视觉，但多 component center
  的无损单实体表达仍受模型限制。
- 原版 transient partial-eraser preview/end 协议仍未完整闭环。
