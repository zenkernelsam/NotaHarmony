# Phase 666 证据：原版打开目标 extras（note_id / nbnote URI / show_library / show_recent）

日期：2026-09-24
关联：ADR-0633；前置 Phase 664（深链管线 + resolveDeepLinkNoteId）、
Phase 665（动作卡片）

## 原版实现（decompiled_1.0.3）

### 投递方（全部 → MainActivity 的 VIEW intent + extras）

| 投递方 | intent 形态 |
|--------|-------------|
| `v50` 近期笔记动态快捷项 | `VIEW` + `putExtra("note_id", ttfVar.toString())` |
| `qk9` 列表小部件行（RecentNotes/FolderNotes 共用 RemoteCollectionItems 模板） | `VIEW` 模板 + 行 `fillInIntent`：`data = Uri.fromParts("nbnote", ttf.toString(), null)` + `putExtra("note_id", ttf.toString())` |
| `bv7` 新窗口目标（`o69Var.I` ttf） | `VIEW` + `putExtra("note_id", ttfVar.toString())` + `addFlags(402657280)` |
| `RecentNotesWidgetProvider` 本体 | `VIEW` + `putExtra("show_recent", true)` |

`nbnote` scheme 仅出现于 fillInIntent 的 data URI —
**AndroidManifest 中无 nbnote 声明**，属内部 URI（`Uri.fromParts`
产出 `nbnote:<ssp>`）。

### 消费端（MainActivity）

`MainActivity.java:467-481`：nav-target 队列 `MainActivity.X` 接收
`vu7` 包装的目标 —— `xu7(noteId)`（打开指定笔记）或 `wu7.a`
（资料库落地）。判定依据即 `getStringExtra("note_id") != null`
与 `getBooleanExtra("show_library", false)`。`show_recent` 的
直接读取点不在 MainActivity 可见代码内（由 nav/区段逻辑消费，
opaque），语义即"近期笔记视图"。

### ID 文本形式

- `ttf.toString()`（`ttf.java:59`）：`xag.c` 把两个 long 写入
  36 字节缓冲并在 8/13/18/23 位放 `-` → **8-4-4-4-12 带连字符
  UUID**。
- `m18.r0`（`m18.java:2875`）：`length==32` → 32-hex 双 long；
  `length==36` → 校验 8/13/18/23 连字符后按 hex 解析同一 ttf；
  其它长度抛 `IllegalArgumentException`。
- 即 `note_id` extra 走 36 位带连字符形式，`/app/note` 深链
  32-hex —— 两者经同一 `m18.r0` 归一化为 `ttf`。

## Harmony 对齐

| 原版 | Harmony |
|------|---------|
| `m18.r0` 双形式解析 | `normalizeDeepLinkNoteId`（DeepLinkIngress）：32-hex 或 8-4-4-4-12 → 统一小写 32-hex |
| `note_id` extra | `OpenTargetIngress`：`want.parameters['note_id']` → 归一化入队 |
| `nbnote:<id>` data URI | `want.uri` 前缀 `nbnote:` → 剩余段归一化入队（uris skill 不声明，同原版内部语义） |
| `show_library` extra → `wu7.a` | `parameters['show_library']===true` → `LibrarySection.ALL_NOTES` |
| `show_recent` extra → 近期视图 | `parameters['show_recent']===true` → `LibrarySection.RECENT` |
| `xu7(noteId)` 打开笔记 | `drainOpenNoteIds` 并入 `drainDeepLinkIngress` → `resolveDeepLinkNoteId`（id + legacy_id）→ `pushUrl NotePage` |

## fail-closed 登记

1. `nbnote` 内部 URI 不注册 uris skill（原版 manifest 亦未声明；
   仅 want.uri 实际投递时接收）。
2. `show_recent` 精确 nav 语义 opaque（kx/导航逻辑内）—— 按
   `LibrarySection.RECENT` 区段处理，为最贴近表达。
3. 打开目标消费依赖本地命中；未命中走深链同一
   `deep_link_note_missing` toast（后端同步取回订阅域 fail-closed）。
