# ADR-1335 — 双指轻点撤销 / 三指轻点重做（undoRedoTapsEnabled）

- 状态：已接受
- 日期：2026-08（Phase 1399）
- 证据：`docs/migration/evidence/phase-1399-original-undo-redo-taps.md`
- Replay：`docs/migration/replays/d02-original-undo-redo-taps.mjs`

## 决策

按原版契约补齐多指轻点历史手势：

- **双指轻点 → 撤销，三指轻点 → 重做**——`TapGesture({count:1, fingers:2/3})`
  挂进画布既有 `GestureGroup(GestureMode.Parallel)`（与双指捏合/平移共存）。
- 对应设置项 `undoRedoTapsEnabled`（原版 `o8b.P`），**缺省 true**
  （`o8b.f` 解码 `null→true`），在设置页"笔记编辑器"区渲染
  `two_finger_tap` 开关行（原版 `kd4` case 15；`nf6`=`j8b.C` UiState）。

## 实现要点

- 持久化走 `EditorSettingsStore` 布尔惯例（`getBooleanPref`/`saveBooleanPref`）；
  `EditorViewModel` init 批量加载，画布回调直接读 `viewModel`。
- 守卫三层：`undoRedoTapsEnabled`（设置关闭即忽略）、`photoImportBusy`
  （导入租约，与 pinch/pan 守卫一致）、`canUndo()/canRedo()`（原版 `i0i`
  明示空栈 undo 为错误路径；且 `performHistory` 会先取消图片裁剪，
  空栈轻拍不应误关裁剪 UI）。

## 行为差异 / 近似说明

1. 原版 `q8j`（Undecided/Scroll/Pinch）显式消歧：只有未演化成滚动/捏合的
   双指接触才算轻点。ArkUI `TapGesture` 内建 touch-slop + 时长容差表达同一
   契约（位移超限即识别失败），故未手写消歧——语义等价，非 fail-closed。
2. Zoom 面板（`NoteZoomView`）是独立组件，本阶段只覆盖主画布；
   原版在 Zoom 内是否接受同样手势未取证，登记为 bounded deferral。
3. `first_undo_redo_tooltip` 首次提示本身（onboarding 气泡系统）未移植，
   属另一类功能面（本阶段只对齐其描述的行为契约）。

## 回归

- 新增 `d02-original-undo-redo-taps.mjs`（35 项断言）。
- `note/src/test/EditorViewModel.test.ets` 的
  `FakeEditorSettingsRepository` 增补 `get/saveUndoRedoTapsEnabled`。
- `note@default` / clean `note@ohosTest` 构建绿，全量 Replay 基线绿。
