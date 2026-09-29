# Phase 1012 证据 — 工具箱/编辑器状态持久化族

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 实体链（Toolbox → Tray → ToolState，FK CASCADE）

```sql
ToolboxEntity{toolbox_id PK,
  mostRecentlySelectedToolId, previouslySelectedToolId}
TrayEntity{tray_id PK, tray_type TEXT,
  toolbox_owner_id→FK(toolbox_id) ON DELETE CASCADE,
  lastUsedToolId}
ToolStateEntity{tool_id AUTOINCREMENT PK,
  tray_owner_id→FK(tray_id) ON DELETE CASCADE,
  toolType TEXT, trayIndex INT,
  color INT?, widthSize REAL?, style INT?,
  selectedColorWellIndex?, selectedWidthSizeWellIndex?,
  tapePattern INT DEFAULT NULL,
  selectionIsFreehand INT DEFAULT 0,
  eraserIsPartial INT DEFAULT 0}
```

- 双层所有权：Toolbox→Tray（type 分类）→
  ToolState（每工具在托盘中的槽位状态）。
- `trayIndex` = 槽位序；`mostRecently/previously` =
  双选记录（切换回退用）。
- `tapePattern`/`selectionIsFreehand`/`eraserIsPartial`
  = 胶带图样/自由套索/局部橡皮标志（含默认值）。

## 井位表（wells）

- `FavoriteColorWellEntity{id, toolType, color,
  trayIndex}` —— 每工具收藏色。
- `WidthSizeWellEntity{id, toolType, width:REAL,
  trayIndex}` —— 每工具笔宽。
- `RecentColorWellEntity{id, color, timestamp}` ——
  最近色时间线。
- 写入 `nullif(?, 0)` = AUTOINCREMENT 占位。

## 纸面/背景

- `PaperBackground{id, paperSize INT,
  paperOrientation TEXT, backgroundColor INT?,
  legacyPaperIndex?, paperLineType, spacing REAL?,
  hasOptions}`。
- `BackgroundInfo{paperLineType PK, spacing,
  hasOptions}` —— 每线型默认间距。

## 编辑器/杂项

- `NoteStateEntity{id BLOB PK(ttf), zoom REAL,
  scrollOffset INT, lastCodeBlockLanguage?,
  zoomViewSourceRect?, zoomViewShown?}` —
  **每笔记视图态**（缩放/滚动/缩放视图标记）。
- `Preference{key TEXT PK, long_value INT?}` ——
  通用 KV。

## Quiz 表（顺带确认写形）

- `QuizSession{noteId,id,mode,numQuestions,
  numAnswered,createdAt,updatedAt,completedAt,
  lastViewedQuestion,questions}`。
- `QuizOp{opId,noteId,mode,sessionId,
  isCompleteSession,questionIndex,status,
  multipleChoiceAnswer,fillInTheBlankAnswer,
  flashcardRating,createdAt}` —— ABORT 写。

## HarmonyOS 决策

- 全族平移 relationalStore（FK CASCADE 保留；
  `nullif(?,0)`→自增占位等价）。
- Harmony 已有 toolbox 状态层须对齐此 schema 语义：
  `trayIndex` 槽序、双选中记录、wells 索引
  (toolType+trayIndex 唯一性需 UNIQUE 约束——
  DDL 未声明，行为由写路径保证)。

## 产出

- fixture `d02-toolbox-persistence.mjs`（14 断言）。
- ADR-0956；中文报告。
