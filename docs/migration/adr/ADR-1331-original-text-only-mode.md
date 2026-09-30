# ADR-1331 — Text-only 视图模式（`isTextOnly` 流式排版 + 自动退出契约）

- 状态：已接受
- 日期：2026-08（Phase 1395）
- 证据：`docs/migration/evidence/phase-1395-original-text-only-mode.md`
- 修订：ADR-1329 对 `is_text_only` 列「仅保列」的暂决——本 Phase 完成行为接入。

## 决策

接入原版 Text-only 视图模式：⋮ 选项菜单 "Text only" 切换 →
`is_text_only` per-note 持久化 → 冷启动恢复 → 文本按页宽流式重排、
非文本元素隐藏 → on/off 横幅 + 自动退出（SwitchedTools/InsertedImage/
ImportedFile/ManualExit）。

## 实现要点

1. **菜单入口**（`pdl.java:214`）：`buildEditorOptionsMenu` 新增
   "Text only" 行（`menuicon_text`），action → `textOnlySignal++`。
2. **持久化**（`xf3/ymb`）：`saveIsTextOnly` 专属写——
   `getViewState`→改字段→`saveViewState`，保留列不丢。
3. **排版**（`x4i→grb.TextOnly`）：`renderFrame` 首插 `isTextOnly` 分支
   → `renderTextOnlyFlow`：`cloneTextBlockElement` 瞬态副本按
   页宽−2×48 重排、`transform=translate(margin,cursorY)` 纵向堆叠，
   `measureTextHeight` 用与 `renderText` 同一套 `layoutLines` 行高口径。
   持久化几何不动；非文本元素（笔画/形状/图片/数学）整支跳过。
4. **自动退出**（`q4i`/`c5i.b`/`xqb.java:216`）：
   - `SwitchedTools`：`EditorViewModel.onToolChanged` 钩子；
     保留集映射为 `{DEFAULT}`（Harmony 无 TEXT/MEDIA/RECORD/POINTER
     枚举，DEFAULT 即文本输入面）。
   - `InsertedImage`：`insertOriginalPhotos` 汇聚点前置退出。
   - `ImportedFile`：`importFileIntoCurrentNote` 成功 →
     `textOnlyExitSignal++`。
   - `ManualExit`：菜单再按。
   - 非 ManualExit 退出 → `text_only_auto_exit` toast（"Showing the
     full note"，d6b snackbar 等价）。
5. **横幅**（`d6b`）：on/off 卡片挂 `hasNonTextElements()` 门；
   on 横幅会话内可 Dismiss（`textOnlyNoticeDismissed`）。

## 有界差异（fail-soft，已记录）

- **流式视图只读**：`beginTextEditingAt`/`toggleCheckboxMarkerAt` 被
  `isTextOnly` 门控。流排副本坐标系与持久化几何不一致，在位编辑会把
  流排尺寸写回块体；进入时先 `suspendTextEditing()` + 清选区。
- **保留集**：原版 {TEXT,MEDIA,RECORD,POINTER} → Harmony {DEFAULT}；
  切到任何工具箱工具即退出（比原版略严——原版 POINTER 选区可活，
  Harmony DEFAULT 之外的 SELECTION 会退出）。
- `InsertedSticky`/`OpenedContentManager`/`LegacyDaemon`：Harmony
  无对应路径，不适用。
- 横幅非文本门按当前页元素集近似；边距/间距为近似值。

## 回归

`d02-original-text-only-mode.mjs`（49 检查）。fixture 引用见本 ADR
与 evidence 文档（满足一致性检查）。
