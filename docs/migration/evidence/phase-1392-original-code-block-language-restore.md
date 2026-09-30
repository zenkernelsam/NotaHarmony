# Phase 1392 证据 — `note_state.last_code_block_language` 每笔记代码块语言记忆

> 源码证据：`decompiled_1.4.2`（1.4.2 APK，v1040002）。本 Phase 解决一个
> **note_state schema 缺口 + 行为缺口**：Harmony 已有代码块语言选择器
> （`TextBlockOverlay` `CODE_LANGUAGES`/`programmingLanguage`），但未持久化
> 「上一次使用的代码块语言」，新代码块缺默认语言恢复。

## 1. 原版 schema（ca3.java:519 → NoteStateEntity）

```sql
CREATE TABLE `NoteStateEntity` (`id` BLOB NOT NULL, `zoom` REAL NOT NULL,
  `scrollOffset` INTEGER NOT NULL, `lastCodeBlockLanguage` TEXT,
  `zoomViewSourceRect` TEXT, `zoomViewShown` INTEGER, `isTextOnly` INTEGER,
  PRIMARY KEY(`id`))
```

`lastCodeBlockLanguage` 是**按笔记持久化**的字段。原版自身的演进迁移
`r4a.java:70`：`ALTER TABLE NoteStateEntity ADD COLUMN lastCodeBlockLanguage
TEXT DEFAULT NULL`（与 Harmony migration 74 同款）。

## 2. 读/写/恢复路径

- `chb.java:44` — `SELECT * FROM NoteStateEntity` 读出
  `lastCodeBlockLanguage`（`isNull ? null : getString`）。
- `ws3.java:277` — `SELECT lastCodeBlockLanguage FROM NoteStateEntity WHERE
  id = ?`：按笔记读取该字段。
- `e83.java:691`/`f83.java:619` — `INSERT`/`UPDATE` 整行写该列。
- **`ya8.java:34`** — `CODE_BLOCK` decorator toggle 分支注释：
  `"CODE_BLOCK needs TextToolbarViewModel.toggleDecorator's
  lastCodeBlockLanguageId restore"` —— 新建代码块时恢复
  `lastCodeBlockLanguage` 作为默认语言（而非 plaintext）。

## 3. Harmony 现状与缺陷

- `TextBlockOverlay.toggleDecoratorStyle`：`decorator===5`(CODE_BLOCK) 且
  `current.programmingLanguage!==undefined` 时保留既有语言；但**新建代码块**
  （`programmingLanguage` 未设）无默认 → 回落 plaintext，丢恢复语义。
- `setCodeLanguage` 设置 `programmingLanguage` 但**不持久化**到 note_state。

## 4. Harmony 实现映射

| 原版 | Harmony |
|------|---------|
| `NoteStateEntity.lastCodeBlockLanguage` | `note_state.last_code_block_language` |
| `r4a:70` ALTER DEFAULT NULL | migration 74 `ALTER TABLE note_state …` |
| `chb:44`/`ws3:277` 读 | `getViewState` 读、`readLastCodeBlockLanguage` |
| `e83`/`f83` 写 | `saveViewState`（undefined→保留）+ `saveLastCodeBlockLanguage` |
| `ya8:34` CODE_BLOCK restore | `toggleDecoratorStyle` decorator=5 新块默认 |
| picker 选语言 → 持久化 | `setCodeLanguage`→`onCodeLanguageSelected`→`persistCodeBlockLanguage` |

## 5. 边界

- `saveViewState` 用 `ON_CONFLICT_REPLACE` 整行重写：`lastCodeBlockLanguage`
  为 `undefined`（viewport 保存路径不带该字段）时**保留已存值**，避免被清。
- plaintext → `null`（清除记忆）；非 plaintext → 存语言名。
- 其余 `NoteStateEntity` 字段（`zoomViewSourceRect`/`zoomViewShown`/
  `isTextOnly`）对应 ZOOM-view 持久化与 text-only 模式，另行 Phase。
