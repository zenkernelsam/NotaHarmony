# Phase 1425：SHAPE 次级条种类选择器移植报告

- 日期：2026-10-01
- 状态：完成（实现阶段；Desktop Replay 13 项本 Phase 检查）
- 证据：`docs/migration/evidence/phase-1425-shape-strip-kind-picker.md`
- 决策：`docs/migration/adr/ADR-1361-shape-strip-kind-picker.md`
- Replay：`docs/migration/replays/d02-original-shape-strip-kind-picker.mjs`

## 目标

补齐原版 `iw4` case8 的 SHAPE 次级工具条交互：折叠态为当前种类图标钮
（`h5g.c`），点击展开为六种类图标行（`h5g.a`/`h5g.b`，`r5g` 序）。
Harmony 此前只能在工具箱设置面板换形状。

## 原版证据

- `iw4.java` case8 → `qri.a` 可展开容器，`jri` 回调切态。
- `h5g.c`：48×48 当前种类钮，a11y = `ui_tools__shape_<kind>`。
- `h5g.a`：六格行，顺序 = `r5g` 枚举序
  RECTANGLE/ELLIPSE/DIAMOND/TRIANGLE/ARROW/LINE。
- `h5g.b`：单元格 accent 高亮 + `shape_*` a11y；点击写回持久化选择。
- 展开随工具会话复位。

## Harmony 改动

| 文件 | 改动 |
|------|------|
| `ShapeKindPicker.ets` | 导出 `SHAPE_KIND_ORDER`、`ShapeKindSwatch`；新增 `compact` 图标态（36dp、无文字、a11y 保留） |
| `EditorViewModel.ets` | 新增 `activeShapeToolId()`（无 SHAPE 行返 `''` 不抛）与 `setActiveShapeKind()`（走 `setToolShapeKind` 校验/持久化） |
| `EditorToolbar.ets` | calligraphy 之后新增 `isShapeActive()` 分支：`@State shapeKindExpandedFor` 按工具 id 记展开态；折叠=单当前种类钮、展开=六格行；accent 选中；`photoImportLeaseActive` 门控 |

工具箱设置面板的 `ShapeKindPicker` 原路径不变。

## 适配与已知差异

- 单元格触控目标 ≈40×40（行高适配原版 48×48）。
- 选中后保持展开至工具切换（原版收起时机不可完全判定，取顺手侧）。
- SHAPE 描边的 `aj1` 凿尖参数（nibAngle=π/2、flatness=0.75）在原版经
  `ox5` 作用于描边几何；Harmony `ShapeCanvasRenderer` 仍为固定线宽——
  记入 ADR-1361 待办，非本期范围。

## 验证

- `d02-original-shape-strip-kind-picker.mjs`：13/13 通过。
- 全量 Desktop Replay、`note@default`、clean `note@ohosTest` 结果见提交说明。
