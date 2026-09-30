# Phase 1361 — `untitled_note` 语义纠正 + string.json 格式还原

## 问题一：`untitled_note` 值误判（对 Phase 1358 的纠正）

Phase 1358 将 `untitled_note` 由 `"New Note"` 改为 `"Untitled"`，依据是原版
`app__shortcut_untitled_note`=`"Untitled"`。**此为末段名碰撞误判**——深读原版后确认：

- `app__shortcut_untitled_note`=`"Untitled"` 仅被 `v50.java` 使用（`ShortcutManager`
  构造应用快捷方式），是**快捷方式标签**，不是笔记标题回退。
- 卡片/列表的空标题回退是 `e5j.h`：`if (str == null) return default_note_title`，
  其中 `data_library_state__default_note_title`=`"New Note"`，被 `bib`/`e5j`/`id7`/
  `ksh`/`nti`/`y5j` 六个卡片/列表合成器使用。

Harmony 的 `untitled_note` 全部 8 个调用点均为 `title.length>0?title:untitled_note`
的**笔记标题回退**（库卡片/编辑器/导入/最近删除/部件卡），无任何应用快捷方式场景。
故正确值是 `"New Note"`（`default_note_title` 语义），已还原；zh 同步 `未命名`→`新笔记`。

## 问题二：`JSON.stringify` 重写破坏资源文件格式（对 Phase 1358-1360 的纠正）

前三批修正用 `JSON.stringify(obj,null,2)` 整体重写 `string.json`，把原本**混排**
（部分单行 `{ "name":"x","value":"y" }`、部分多行）的 654 个条目统一规范成多行，
导致 ~126 个以单行文本模式 `includes('"k", "value": "..."')` 断言的 Replay 失配。

已改为**格式保留式注入**：以 `4549008a`（改动前）文本为底，仅把当前正确的值
按各条目原有行形写回，`git diff` 净剩纯 `"value"` 行变更。

## 验证

- `d02-untitled-format-restore.mjs`：10/10（含格式守卫，防再次 reserialize 失配）。
- 全部 126 个引用 `string.json` 的 Replay 通过（原失败 fixture 复绿）。
- `d02-ui-wording-fix`/`d02-string-diffs`/`d02-original-page-selection-count`/
  `d02-original-library-title-fallback`/`d02-original-import-confirm-label` 全绿。

## 结论

- `untitled_note` = `"New Note"`/`"新笔记"`（卡片空标题回退），"Untitled" 仅快捷方式标签。
- 资源文件恢复原混排格式；Phase 1358/1359/1360 的正确措辞修正全部保留。
