# Phase 1395 报告 — Text-only 视图模式（`isTextOnly` 流式排版 + 自动退出）

- 阶段：1395
- ADR：ADR-1331
- 证据：`docs/migration/evidence/phase-1395-original-text-only-mode.md`
- Replay：`docs/migration/replays/d02-original-text-only-mode.mjs`（49 检查）

## 背景

`note_state.is_text_only`（`NoteStateEntity.isTextOnly`）在 Phase 1393 完成
保列 round-trip。本 Phase 接入原版行为：⋮ 选项菜单 "Text only" 切换
（`pdl.java:214` → `jzi.onTextOnlyModeToggle`），经 `x4i` 组合出
`grb.TextOnly` 排版模式——文本按文档宽重排、非文本元素隐藏，是阅读优化
的真·重排而非隐藏滤镜。退出走 `c5i.b(q4i)` 统一出口，原因枚举
`ManualExit`/`SwitchedTools`/`InsertedImage`/`ImportedFile`/`InsertedSticky`/
`OpenedContentManager`/`LegacyDaemon`；`xqb.java:216` 工具白名单
{TEXT,MEDIA,RECORD,POINTER} 外切换即 SwitchedTools 退出。

## 修复

- **菜单入口**：`buildEditorOptionsMenu` 新增 "Text only" 行
  （`menuicon_text`，与原版一致）→ `textOnlySignal++` →
  `NoteCanvasView.onTextOnlySignalChange` → `setTextOnly`。
- **持久化**：`NoteRepository.saveIsTextOnly` 专属写（xf3/ymb 等价），
  `getViewState`→改字段→`saveViewState` 全列保留。
- **恢复**：`loadNoteData` 载入 `isTextOnly`；为 true 且工具≠DEFAULT →
  `selectTool(DEFAULT)`（进入即落文本工具面，eti 保留集语义）。
- **排版**：`renderFrame` 首插 `isTextOnly` 分支 → `renderTextOnlyFlow`：
  `cloneTextBlockElement` 瞬态副本按页宽−2×`TEXT_ONLY_FLOW_MARGIN` 重排、
  `transform=translate(margin,cursorY)` 逐块堆叠、`measureTextHeight`
  同 `renderText` 行高口径；非文本元素全部跳过；持久化几何不变。
- **自动退出**：`EditorViewModel.onToolChanged` 钩子 → 非 DEFAULT 工具
  `SwitchedTools` 退出；`insertOriginalPhotos` 汇聚点 `InsertedImage`；
  `importFileIntoCurrentNote` 成功 → `textOnlyExitSignal` `ImportedFile`；
  菜单再按 `ManualExit`。非 ManualExit 退出弹 `text_only_auto_exit` toast。
- **横幅**（`d6b`）：on/off 卡片挂 `hasNonTextElements()` 门
  （"This note contains non-text elements…"）；on 横幅 Dismiss 会话内记忆
  （`zkb.onTextOnlyNoticeDismissed`），off 横幅可 Dismiss
  （`onTextOnlyAutoExitBannerDismissed`）。
- **收尾**：进入时 `suspendTextEditing()` + 清选区（流排坐标系下旧位
  编辑面失效）；`aboutToDisappear` 清 `onToolChanged` 订阅。

## 行为差异（相对 Harmony 旧行为 / 有界适配）

- 流式视图为**只读**：`beginTextEditingAt`/`toggleCheckboxMarkerAt` 被
  `isTextOnly` 门控——流排副本坐标系与持久化几何不一致，在位编辑会把
  流排尺寸写回块体。
- 保留集 {TEXT,MEDIA,RECORD,POINTER} → Harmony {DEFAULT}；切到任何
  工具箱工具即退出（比原版略严）。
- `InsertedSticky`/`OpenedContentManager`/`LegacyDaemon` 无对应 Harmony
  路径，不适用。
- 横幅非文本门按当前页元素集近似；流排边距/间距（48/24）为近似值。

## 改动文件

- `note/src/main/ets/data/RepositoryInterfaces.ets` — `saveIsTextOnly`
- `note/src/main/ets/data/NoteRepositoryImpl.ets` — 专属写
- `note/src/main/ets/ui/editor/EditorViewModel.ets` — `onToolChanged` 钩子
- `note/src/main/ets/ui/editor/NoteCanvasView.ets` — `isTextOnly` 态、
  `setTextOnly`/`exitTextOnly`/`persistIsTextOnly`、信号 watch、
  `renderTextOnlyFlow`、横幅卡片、只读门、恢复路径
- `note/src/main/ets/ui/editor/NotePage.ets` — 菜单行、信号态、
  ImportedFile 出口、canvas props
- `note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets` —
  `measureTextHeight`
- `note/src/main/resources/{base,zh_CN}/element/string.json` — 7 条资源
- `docs/migration/replays/d02-original-text-only-mode.mjs`（新增）

## 验收

- 硬证据：`strings.xml:733/768-774`、`pdl.java:214`、`anb.java`、
  `xf3.java`/`ymb.java`、`x4i.java`、`c5i.java`、`q4i.java`、
  `xqb.java:216`、`d6b.java`。
- `d02-original-text-only-mode` 49 检查绿；全量基线全绿。
- `note@default`/`note@ohosTest` HAP 构建成功，无新增 ArkTS 错误。

## fail-closed / 边界

见 ADR-1331「有界差异」。流式视图只读是本 Phase 主要裁剪点。
