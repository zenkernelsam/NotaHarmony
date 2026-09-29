# Phase 1026 证据 — Preference KV + NoteStateEntity

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `Preference` = app 键值表

```sql
CREATE TABLE `Preference` (
  key TEXT PK, long_value INTEGER)
-- na4: INSERT OR REPLACE INTO Preference(key,long_value)
```

- **key→long 简单 KV**——非 WorkManager 的同名内部
  表（e47 的 `Preference(androidx.work.impl.model...)`
  验证错误串是 WorkManager 的；app 表在 na4 端）。
- 仅存 long 值——计数/标志/枚举类。

## `NoteStateEntity` = 每笔记编辑器 UI 态

```sql
CREATE TABLE `NoteStateEntity` (
  id BLOB PK,                 -- noteId
  zoom REAL NOT NULL,         -- 缩放级别
  scrollOffset INTEGER,       -- 滚动偏移
  lastCodeBlockLanguage TEXT, -- 上次代码块语言
  zoomViewSourceRect TEXT,    -- 缩放视图源矩形 JSON
  zoomViewShown INTEGER)      -- 缩放视图可见
```

- `na4` INSERT 6 列；nullable：lastCodeBlockLanguage/
  zoomViewSourceRect/zoomViewShown。
- 恢复会话 UI 态：缩放+滚动位置+代码块语言+
  缩放视图矩形/可见性。

## `Preference` 与 `NoteStateEntity` 分工

| 表 | 粒度 | 用途 |
|---|---|---|
| Preference | 全局 key→long | 设置/标志 |
| NoteStateEntity | per-noteId | 编辑器 UI 恢复态 |

## HarmonyOS 决策

两表平移；NoteStateEntity 的 zoom/scroll/rect
语义保留（编辑器恢复）；Preference 仅 long 值
（如需 string 另建）。

## 产出

- fixture `d02-preference-notestate.mjs`（10 断言）。
- ADR-0970；中文报告。
