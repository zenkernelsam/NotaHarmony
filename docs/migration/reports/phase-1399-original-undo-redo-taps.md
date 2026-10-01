# Phase 1399 — 原版双指轻点撤销 / 三指轻点重做（undoRedoTapsEnabled）

- ADR：`docs/migration/adr/ADR-1335-original-undo-redo-taps.md`
- 证据：`docs/migration/evidence/phase-1399-original-undo-redo-taps.md`
- Replay：`docs/migration/replays/d02-original-undo-redo-taps.mjs`（35 项）

## 背景

静态审计收尾扫到 `data_onboarding__first_undo_redo_tooltip_text`
（"Two finger tap to quickly Undo, three finger tap to Redo"）——原版画布
支持双指轻点撤销、三指轻点重做，且由编辑器设置 `undoRedoTapsEnabled`
控制（`o8b.P`）。Harmony 此前只有工具栏撤销/重做按钮，无多指手势，
设置页也缺该行。本 Phase 按原版契约补齐手势 + 设置开关。

## 原版证据

- 字符串：`feature_settings__two_finger_tap` = "2 finger tap" /
  `_description` = "2 finger tap to undo, 3 finger tap to redo."；
  onboarding 首次提示同款文案。
- `o8b.java:43` `dcd("undoRedoTapsEnabled")`；`o8b.f` 解码 `null→true`
  ——缺省 true。
- `kd4.java` case 15：设置页开关行（nf6=`j8b.C` UiState 驱动）。
- `q8j`（Undecided/Scroll/Pinch）：轻点只在未演化成滚动/捏合时成立。
- `i0i`：空栈 undo 是错误路径——故接 `canUndo()/canRedo()` 前置守卫。

## Harmony 实现

- `EditorSettingsStore`：`UNDO_REDO_TAPS_KEY='undoRedoTapsEnabled'` +
  `DEFAULT_UNDO_REDO_TAPS=true`，接口/实现按既有布尔惯例。
- `SettingsPage`：笔记编辑器区新增"双指轻点"开关行（原文案逐字），
  乐观更新 + 失败回滚 + 生命周期守护同款模式。
- `EditorViewModel.undoRedoTapsEnabled`：init 批量加载。
- `NoteCanvasView`：Parallel 手势组内新增
  `TapGesture({count:1, fingers:2})`→`undoStroke()`、
  `TapGesture({count:1, fingers:3})`→`redoStroke()`；
  回调门控 = 设置开启 ∧ 非 photoImportBusy ∧ 栈非空。

## 行为差异 / 近似说明

1. 原版 `q8j` 显式消歧（未滚动/捏合才算轻点）→ ArkUI TapGesture 内建
   touch-slop + 时长容差表达同一契约，语义等价，未手写消歧。
2. 覆盖范围限主画布；Zoom 面板内是否接受同手势未取证，
   登记为 bounded deferral。
3. `first_undo_redo_tooltip` 的 onboarding 气泡本身未移植
   （只对齐其描述的行为契约）。

## 验证

- 新增 35 项断言全绿；`note@default` / clean `note@ohosTest` 构建绿；
  全量 Desktop Replay 基线绿。
