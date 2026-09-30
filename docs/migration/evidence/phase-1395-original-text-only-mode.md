# Phase 1395 证据 — Text-only 视图模式（仅文本流式排版）

## 原版 1.4.2 硬证据

| 证据 | 位置 | 内容 |
|------|------|------|
| 菜单入口 | `resources/res/values/strings.xml` | `feature_note__options_menu_text_only` = "Text only" |
| 菜单回调 | `defpackage/pdl.java:214` | `onTextOnlyModeToggle(Z)V` — ⋮ 选项菜单切换回调 |
| 状态列 | `defpackage/anb.java` | `NoteStateEntity.isTextOnly`（per-note 持久化） |
| 专属写 | `defpackage/xf3.java` / `ymb.java` | `is_text_only` 专属 UPDATE（与 zoomViewShown 同型 partial update） |
| 排版模式 | `defpackage/x4i.java` | `(isTextOnly, contentHeight, docWidth) → hrb`：`frb.Standard` vs `grb.TextOnly` —— 真·重排模式（重算 contentHeight），非隐藏滤镜 |
| 统一出口 | `defpackage/c5i.java` | `b(q4i reason)` — 所有退出路径收敛点 |
| 退出原因 | `defpackage/q4i.java` | `ManualExit`/`SwitchedTools`/`InsertedImage`/`ImportedFile`/`InsertedSticky`/`OpenedContentManager`/`LegacyDaemon` |
| 工具白名单 | `defpackage/xqb.java:216` | `SwitchedTools`：保留集 = `eti` 序数 {4=TEXT, 7=MEDIA, 8=RECORD, 9=POINTER}；其余工具切换即退出 |
| 横幅 | `defpackage/d6b.java` | on/off 双横幅（`zkb.onTextOnlyNoticeDismissed` / `onTextOnlyAutoExitBannerDismissed`）；挂"笔记含非文本元素"门（z14） |
| Toast | strings.xml:768 | `feature_note__text_only_auto_exit` = "Showing the full note"（自动退出 snackbar） |

## 原文案全文

```
options_menu_text_only        = "Text only"
text_only_auto_exit           = "Showing the full note"
text_only_banner_dismiss      = "Dismiss"
text_only_banner_on_title     = "Text only mode on"
text_only_banner_on_body      = "This note contains non-text elements but is
                                 optimized as text only for easier reading.
                                 Go to Note options and turn off Text only to
                                 view this note in its original format."
text_only_banner_off_title    = "Text only mode off"
text_only_banner_off_body     = "The view setting has changed to accurately
                                 display non-text elements in the note."
```

## Harmony 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `onTextOnlyModeToggle` 菜单项 | `NotePage.buildEditorOptionsMenu` 新增 "Text only" 行（`menuicon_text`）→ `textOnlySignal++` |
| `is_text_only` 专属 UPDATE | `NoteRepository.saveIsTextOnly`（preserve 全列后 saveViewState） |
| `anb.g → hrb` 恢复 | `loadNoteData`：`isTextOnly = state?.isTextOnly === true`；为 true 且工具≠DEFAULT → `selectTool(DEFAULT)` |
| `eti` 保留集 {TEXT,MEDIA,RECORD,POINTER} | Harmony 无对应枚举 → `{DEFAULT}`（DEFAULT 即文本输入面）；其余工具切换 → `exitTextOnly('SwitchedTools')` |
| `SwitchedTools` | `EditorViewModel.onToolChanged` 出口钩子（applyActiveState 内 nextTool≠currentTool 时发射） |
| `InsertedImage` | `insertOriginalPhotos` 汇聚点（照片/拍照/剪贴板三路）前置 `exitTextOnly` |
| `ImportedFile` | `importFileIntoCurrentNote` 成功落盘 → `textOnlyExitSignal++` |
| `ManualExit` | 菜单再次点按 → `setTextOnly(false, 'ManualExit')`（不弹 auto-exit toast） |
| on/off 横幅 | `textOnlyBannerOn`/`textOnlyBannerOff` @State 卡片 + Dismiss；仅在 `hasNonTextElements()` 时出现 |
| `grb.TextOnly` 重排 | `renderTextOnlyFlow`：`cloneTextBlockElement` 瞬态副本，blockWidth=页宽−2×48，transform=translate(margin,cursorY)，纵向堆叠；`measureTextHeight` 同口径量高 |

## 有界差异（ADR-1331 记录）

1. 流式视图为**只读**：`beginTextEditingAt`/`toggleCheckboxMarkerAt` 被 `isTextOnly` 门控。
   流排副本的坐标系与持久化几何不一致，在位编辑会把流排尺寸写回块体。
   原版在流式布局下可继续编辑文本；Harmony 版进入时先 `suspendTextEditing()`
   收尾并清选区。
2. 保留集映射：原版允许 TEXT/MEDIA/RECORD/POINTER；Harmony 无这四枚工具
   枚举，以 DEFAULT（文本输入面）近似 TEXT；切到任何工具箱工具即退出。
3. `InsertedSticky`/`OpenedContentManager`/`LegacyDaemon`：Harmony 无
   贴纸插入、内容管理器、后台守护路径 → 不适用。
4. 横幅非文本元素判定按**当前已载页**元素集近似（原版为整笔记判定）。
5. 页边距/块间距为近似值（48/24 doc 单位）；原版排版器边距参数不可见。
