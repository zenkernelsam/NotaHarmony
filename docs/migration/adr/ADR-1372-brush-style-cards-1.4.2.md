# ADR-1372 — 笔画样式选择器按 1.4.2 卡片行对齐；SHAPE 约束标记判定为休眠代码

## 状态

Accepted（已实施并验证）。

## 背景

Phase 1386 依据 1.0.3 `x4j.java` 证据实现了 icon-only 波形样式选择器
（44×24 `ui_tools__brushstyle_*` 矢量，无可见文本）。1.4.2 重新检查后，
原版样式选择器已演进为 `azm.c`/`u4h` 卡片行；同时 Phase 1409 遗留的
"SHAPE 线型选择器 / 约束修饰源留待后续"注释需要结案。

## 原版 1.4.2 证据

1. `yxi.java:79-82`：样式行顺序 = Variable(Taper) → Fixed(Mono) →
   Dashed → Dotted。Harmony 旧实现按 `o81` 枚举序排列
   （Mono, Taper, Dash, Dot），前两项与 UI 显示序相反——为真实缺陷。
2. `azm.c`/`u4h`/`lri`/`ne`：每个选项为 `weight(1f)` 等宽圆角卡片，
   1.5dp 描边（选中 accent / 未选透明），卡面选中 accent-container /
   未选 surface，内容 24dp `line_style_*` 图标 + 文本标签纵向排列，
   内容着色恒定 `a.c.b`。
3. 样式行仅挂 `n5h` 实现者 `csi`(PEN)/`wri`(HIGHLIGHTER)；
   `psi`(SHAPE) 非 `n5h`，`dwi` SHAPE 分支只发 `h5g` 形状种类，
   `CREATE_SHAPE` 载荷无线型字段。
4. `j1k.q` 约束 flag：全源树无写入点（`m(boolean)` 零调用者）；
   Shift 捕获 `h8d.e`/`ihl.c` 仅馈入 `sgn.Y`/`pba` 选择分支。
   → 1.4.2 中 SHAPE 约束为 dead code。

## 决定

1. **样式选择器按 1.4.2 证据重做**：
   - 顺序统一 Variable, Fixed, Dashed, Dotted（工具行与选区行）。
   - 采用 `ui_designsystem__line_style_*` 24dp 矢量 + 可见标签的等宽
     描边卡片；`line_style_fixed` 以负视口原点复刻 `translate(0.625)`。
   - 选中态 = accent 描边 + accent 弱透明卡面；未选 = 透明描边 + control 面；
     内容着色恒定 textPrimary。
   - 1.0.3 `BRUSH_STYLE_GLYPHS` 波形资产保留（不再消费），fixture 更新为
     钉 1.4.2 实现并注明版本差异。
2. **SHAPE 过期注释闭环**：`constrain=false` 判定为精确对齐
   （`ShapeDragGeometry.ets` 注释已更新）；不添加 SHAPE 线型选择器；
   不激活约束（无 1.4.2 写入点，启用即发明行为）。
3. **导出扫描轴复核**：`xx4` 导出仓储（24h TTL/500MB 上限/15min 周期）
   已由 `NoteExportTemporaryArtifactCleanup.ets` 等价覆盖，无需新增实现。

## 后果

- UI 可见变化：样式行由 icon-only 波形变为 icon+label 卡片，首两项顺序
  由 [Mono, Taper] 更正为 [Variable, Fixed]。
- `BrushStyle` 模型与持久化语义不变（改动仅限选择器呈现）。
- 选区设置面板高度 64→104 容纳两行控件。

## 证据与验证

- 证据：`docs/migration/evidence/phase-1437-brush-style-cards.md`
- Replay：`d02-original-brush-style-glyphs.mjs`（34 checks）、
  `d02-original-selection-mode-toggle.mjs`（27 checks）全绿；
  全量基线 1287/1287 待本阶段复跑确认。
- 构建：`note@default`、`note@ohosTest` HAP 构建通过。
