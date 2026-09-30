# Phase 1393 证据 — `note_state` 补齐 `NoteStateEntity` 全列

> 源码证据：`decompiled_1.4.2`（1.4.2 APK，v1040002）。本 Phase 完成
> `note_state` 对 `NoteStateEntity`（`ca3.java:519`，8 列）的**全列对齐**，
> 使导入的原版 note_state 行 round-trip 不丢列。

## 1. NoteStateEntity 全列（ca3.java:519）

```sql
CREATE TABLE `NoteStateEntity` (
  `id` BLOB NOT NULL, `zoom` REAL NOT NULL, `scrollOffset` INTEGER NOT NULL,
  `lastCodeBlockLanguage` TEXT, `zoomViewSourceRect` TEXT,
  `zoomViewShown` INTEGER, `isTextOnly` INTEGER, PRIMARY KEY(`id`))
```

| 列 | 原版读/写 | Harmony 对齐 |
|----|-----------|--------------|
| `lastCodeBlockLanguage` | chb:44 / e83·f83 / **ya8:34 restore** | Phase 1392 已对齐 |
| `zoomViewSourceRect` | chb:45 / **wmb:102 UPDATE** / `ten.y` 解 `"l,t,r,b"`（`sbe`） | 本 Phase 列 |
| `zoomViewShown` | chb:46 / **wmb:75 UPDATE** | 本 Phase 列 |
| `isTextOnly` | chb:47 / **xf3:103 UPDATE** | 本 Phase 列 |

## 2. 序列化格式

`ten.r`/`ten.y`：`sbe` 矩形 `a,b,c,d`（left,top,right,bottom floats）→
逗号串 `"l,t,r,b"`；`sbe.e`=(0,0,0,0) 为默认/空。

## 3. Harmony 处理

- **`zoom_view_source_rect`/`zoom_view_shown`**：Harmony 放大窗用
  **tool-gated 模型**（`isShown`=ZOOM 工具激活即挂载，`initZoomSourceRect`
  锚定末笔/视口中心），与原版「持久化 shown+rect、reopen 恢复」模型不同——
  本 Phase **保列 round-trip**，行为维持 Harmony 现行（不强行切模型）。
- **`is_text_only`**：原版「Text only」视图模式（`options_menu_text_only` +
  `text_only_banner_*` + auto-exit）——隐藏非文本元素的渲染模式，是独立
  Phase（渲染管线+横幅+auto-exit）。本 Phase **保列**。
- **`saveViewState`** 增 `readPreservedNoteState`：`ON_CONFLICT_REPLACE`
  整行重写前，4 个保留列 `undefined`→读现值（viewport 保存不误清导入值）。
  布尔列写 INTEGER 0/1。

## 4. 结论

`note_state` 8/8 列齐：id/zoom/scrollOffset×2/coordver/lastCodeBlockLanguage/
zoomViewSourceRect/zoomViewShown/isTextOnly。zoomView*/isTextOnly 行为接入
留待对应 Phase（放大窗持久化恢复 / text-only 渲染模式）。
