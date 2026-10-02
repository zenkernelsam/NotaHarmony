# Phase 1473 报告：Alt 井选择键（bxi 色井 / dxi 宽度井 / exi 步进）

## 原版行为（1.4 证据）

键盘兜底链 `f2.java:264-276`（`!rsi` 门内、PAGE_DOWN 支后、
媒体支前）经 `hxi.a` 事件通道 → `qxi` case0 消费：

- **Alt+digit**（`db8.q && !db8.r && !db8.s`，`bd8.i0`=
  KEYCODE_1..9）→ `bxi(index)`：`e52.s3(index, jyi.B())`
  取第 N 色井 → `jyi.A` 应用（`k31.X(wsi, g92(c,d))`）。
- **Alt+Shift+digit**（`q && !r && s`）→ `dxi(index)`：`s2k`
  宽度井列表按当前工具类型 `a6n.c(type)` 过滤+`iyi` 排序 →
  `k31.Y(wsi, r2k(d,c))` → `jyi.F` 应用宽度。
- **Alt+[ / Alt+]**（`q && !r`，**shift 不判**）→ `exi(∓1)`
  StepColor：`jyi.B()` 内按 `x25.d==g92.b` 色值 indexOf 定位
  当前井，缺失 0 基，`(i2+delta) floorMod size` 回卷 → `jyi.A`。
- `jyi.B()` = `x25` 色井列表按 `a6n.c(type)` 过滤 + `ttb` 排序。
- 三支 UP 动作、命中即消费；`e52.s3` 越界 null → no-op。

## Harmony 缺口

`selectFavoriteColor`/`selectWidthWell` 管线齐备
（`favoriteColors`/`widthWells` 按 `activeToolType` 载入 =
`jyi.B()`/`s2k` 过滤等价），但键盘无 Alt 通路。

## 实现

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_LEFT_BRACKET=2059`、
  `ORIGIN_KEYCODE_RIGHT_BRACKET=2060`（SDK 枚举核实）；
  `altWellDigitIndex` helper（`alt&&!ctrl` 门 + 共享
  `ORIGIN_TOOL_SELECT_DIGIT_BASE`/`END` 索引基 = `bd8.i0`）。
- `NoteCanvasView` `!textEditing` 块内（PAGE_DOWN 支后、媒体支前，
  对齐 f2 链序）增两支：alt digit → shift 分流
  `onKeySelectWidthWell`/`onKeySelectColorWell`；
  alt+[/]（不查 shift）→ `onKeyStepColorWell(∓1)`；均 UP 动作 +
  无条件消费。
- `NotePage` 三回调 → `viewModel.selectFavoriteColor /
  selectWidthWell / stepFavoriteColor`。
- `EditorViewModel.stepFavoriteColor(delta)`：`indexOf(brushColor)`
  色值定位（非存序索引）→ 缺失 0 基 → floorMod 回卷 →
  `selectFavoriteColor`；空表 no-op。

## 验证

- `d02-original-alt-well-keys.mjs`：33 checks 全绿（键码/helper
  门控/shift 分流/[/]方向/消费语义/接线/VM pin/可执行模型）。
- `note@default` + `note@ohosTest` clean 构建成功。
- 全量 Replay 基线：见本阶段提交说明。

## 差异

- 原版 `hxi.a` 协程通道；Harmony 同步回调，结果等价。
- `ttb`/`iyi` 排序键 = 井序数；Harmony 井列表本身按序数存储，
  序等价。

## 关联

- evidence/phase-1473-alt-well-keys.md
- ADR-1408-alt-well-keys
