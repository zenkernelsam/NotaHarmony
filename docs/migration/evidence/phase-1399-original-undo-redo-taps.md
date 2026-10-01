# Phase 1399 证据 — 原版双指轻点撤销 / 三指轻点重做（undoRedoTapsEnabled）

## 原版证据（decompiled_1.4.2）

### 行为契约

- `resources/res/values/strings.xml`：
  - `data_onboarding__first_undo_redo_tooltip_text`
    = "Two finger tap to quickly Undo, three finger tap to Redo"
    —— 首次提示直接给出双指=撤销、三指=重做的契约。
  - `feature_settings__two_finger_tap` = "2 finger tap"
  - `feature_settings__two_finger_tap_description`
    = "2 finger tap to undo, 3 finger tap to redo."

### 设置项与持久化

- `defpackage/o8b.java:43`：`public static final dcd P = new dcd("undoRedoTapsEnabled")`
  —— 编辑器设置 proto 字段。
- `defpackage/o8b.java:443-446`：解码缺省 —
  `bool6 = fcd.b(P); zBooleanValue6 = bool6 != null ? bool6 : true`，
  即 **缺省 true**（opt-out 语义）。
- `defpackage/nf6.java`：`nf6(boolean)` = `undoRedoTapsEnabled` 的 UiState；
  `qf6` 用 `nf6(((j8b) o8bVar.i().getValue()).C)` 构造——`j8b.C` 即该布尔。
- `defpackage/kd4.java:207-224`（case 15）：设置页渲染 `two_finger_tap`
  标题 + description 的开关行，切换写回 `o8b.P`。

### 手势消歧

- `defpackage/q8j.java`：双指手势消歧枚举 `{Undecided, Scroll, Pinch}`——
  原版只在双指接触**未演化成**滚动/捏合时才算轻点。
  ArkUI `TapGesture` 内建相同契约：指针移出 touch slop 或超时即识别失败，
  语义等价，无需额外手写消歧。

### 空栈保护

- `defpackage/i0i.java:1380`："It's an error to call undo while there is
  nothing to undo."——原版撤销栈空时调用属错误路径。
- Harmony 端 `performHistory` 虽对空组早退，但其前序步骤会先
  `cancelImageCrop()`；故 TapGesture 回调先判 `canUndo()/canRedo()`，
  避免"无可撤销时双指轻点误关裁剪 UI"。

## Harmony 实现映射

| 原版 | Harmony |
|------|---------|
| `o8b.P` proto 字段 `undoRedoTapsEnabled` | `EditorSettingsStore` `UNDO_REDO_TAPS_KEY='undoRedoTapsEnabled'` |
| 缺省 true（`o8b.f` null→true） | `DEFAULT_UNDO_REDO_TAPS=true` |
| `kd4` case 15 开关行 | SettingsPage 笔记编辑器区"双指轻点"行（`two_finger_tap` 文案逐字） |
| `nf6(j8b.C)` UiState | `EditorViewModel.undoRedoTapsEnabled`（init 加载） |
| 双指轻点 → Undo | `TapGesture({count:1, fingers:2})` → `undoStroke()` |
| 三指轻点 → Redo | `TapGesture({count:1, fingers:3})` → `redoStroke()` |
| `q8j` 未滚动/未捏合才算轻点 | ArkUI TapGesture 内建 slop/时长容差（等价语义） |
| `i0i` 空栈错误路径 | 回调前置 `canUndo()/canRedo()` 守卫 |

## 移植说明

- TapGesture 与既有 `PinchGesture`/`PanGesture` 共处
  `GestureGroup(GestureMode.Parallel)`：轻点快速抬指命中 tap；
  发生位移则 tap 识别失败、pinch/pan 正常——与原版 `q8j` 消歧等价。
- `photoImportBusy` 租约守卫与 pinch/pan 的既有守卫一致。
- 覆盖范围限主画布（`NoteCanvasView`）；Zoom 面板为独立组件，
  本阶段不含其内嵌轻点（属 bounded deferral）。
