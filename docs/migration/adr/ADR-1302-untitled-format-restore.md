# ADR-1302 — `untitled_note` 语义纠正 + string.json 格式还原

## 状态

Accepted（已落地，纠正 Phase 1358 的误判与其 reserialize 副作用）。

## 背景

Phase 1358 将 `untitled_note` 由 `"New Note"` 改为 `"Untitled"`，误判依据是
`app__shortcut_untitled_note`="Untitled"（末段名碰撞）。同时 1358–1360 用
`JSON.stringify(...,2)` 重写 `string.json`，把原混排格式规范成统一多行，
破坏了一批按单行模式断言的 Replay。

## 决策

1. **`untitled_note` 还原为 `"New Note"`**（zh `"新笔记"`）。证据：`e5j.h` 空标题回退
   返回 `data_library_state__default_note_title`="New Note"，被 6 个卡片/列表合成器
   使用；而 "Untitled" 仅是 `v50` 的 `ShortcutManager` 快捷方式标签，Harmony 无此场景。
   `untitled_note` 的 8 个调用点全是笔记标题回退，应显示 "New Note"。
2. **string.json 格式还原**：以 `4549008a`（改动前混排格式）为底，格式保留式注入
   当前正确值，恢复单行/多行原状，修复失配的 Replay。

## 刻意保留

- 1358/1359/1360 的全部**正确**措辞修正（widget 描述、大小写、对话框按钮等）。
- `record_audio`/`new_note`/`add_page` 等 1360 修正（均有完整键名+调用点双重确认）。

## 依据

- 证据：`docs/migration/evidence/phase-1361-untitled-format-restore.md`
- 报告：`docs/migration/reports/phase-1361-untitled-format-restore.md`
- Replay：`d02-untitled-format-restore.mjs`（10/10，含格式守卫）

## 后果与教训

- 资源/源码修改须**最小 diff**，禁止对带既有排版的文件做 `JSON.stringify` 整体重写；
  应做行内精准替换。
- 同名/末段键匹配须**完整键名 + Harmony 调用点**双重确认方可改值；
  短捷径标签≠笔记标题回退。
- 新增格式守卫断言，防再次整体重写破坏文本模式断言。
