# Phase 1437 — 笔画样式选择器 1.4.2 卡片行对齐 + SHAPE 过期注释闭环

## 阶段目标

将笔/荧光笔的笔画样式选择器从 1.0.3 icon-only 波形升级为 1.4.2 原版
icon+label 卡片行，并闭环 Phase 1409 遗留的 SHAPE 线型/约束待办注释。

## 原版调查结论

### 样式选择器（1.4.2）

- `yxi.java:79-82` 按序构造四枚 `u4h`：Variable(Taper)、Fixed(Mono)、
  Dashed、Dotted —— UI 显示序与 `o81` 枚举序（Mono,Taper,Dash,Dot）不同。
- `azm.c`/`u4h`/`lri`/`ne`：选项为 `weight(1f)` 等宽圆角卡片，1.5dp 描边
  （选中 accent / 未选透明），卡面选中 accent-container / 未选 surface，
  内容 = 24dp `ui_designsystem__line_style_*` 图标 + 文本标签纵排。
- 样式行仅挂 `n5h` 实现者：`csi`(PEN)、`wri`(HIGHLIGHTER)。
- `psi`(SHAPE) 非 `n5h`；`dwi` SHAPE 面板只发 `h5g` 形状种类；
  `CREATE_SHAPE` 无 line-style 字段。

### SHAPE 约束（j1k.q）休眠判定

- `u5g`/`j1k.q` 约束 flag（矩形→正方形、线/箭头→45° 吸附）存在 setter
  `m(boolean)`，但全源树零调用者。
- Shift 捕获链 `h8d.e`/`ihl.c` 仅馈入 `sgn.Y`/`pba` 选择分支，不入 SHAPE。
- 结论：1.4.2 中 `j1k.q` 为 dead code；Harmony `constrain=false` 即精确对齐。

### 导出扫描复核

- `xx4` 导出仓储（24h TTL、500MB 上限、15min WorkManager 周期、oldest-first
  清扫、pinned/active 保护）已由 `NoteExportTemporaryArtifactCleanup.ets`
  等价覆盖（`Context.tempDir` 中断残留清理 + `finally` 成功路径删除），
  无需新增实现。

## Harmony 变更

- `BrushStyleGlyphs.ets`：新增 `LINE_STYLE_GLYPHS`（4 枚 1.4.2 矢量，
  pathData 逐字；fixed 以 vx/vy=-0.625 复刻 `translate(0.625)`）；
  `BrushStyleGlyph` 扩展可选 `vx`/`vy`；1.0.3 `BRUSH_STYLE_GLYPHS`
  保留为历史证据。
- `EditorToolbar.ets`：新增 `lineStyleGlyph`/`LineStyleIconView`/
  `styleCardSelectedBackground`；`StyleButton`/`SelectionStyleButton`
  改为 icon+label 等宽描边卡片；两行顺序 Variable→Dotted；
  工具行高 52、选区容器高 104；Taper 选区门控与 a11y 保留；
  移除旧波形渲染方法与 `BRUSH_STYLE_GLYPHS` 消费。
- `ShapeDragGeometry.ets`：注释更新为 j1k.q 休眠证据。
- 字符串：en Variable/Fixed/Dashed/Dotted；zh 可变/固定/虚线/点线。

## Replay / 构建

- `d02-original-brush-style-glyphs.mjs` 重写为钉 1.4.2 卡片行（34 checks 绿）。
- `d02-original-selection-mode-toggle.mjs` 锚点改 `brush_style_variable`（绿）。
- 全量 Desktop Replay、双 HAP 构建结果见阶段提交说明。

## 文档

- ADR-1372、phase-1437 证据文档、本报告。
- `修复总纲.md`、`修复总纲2.md`、`修复进展-2026-08-09.md` 已同步。
