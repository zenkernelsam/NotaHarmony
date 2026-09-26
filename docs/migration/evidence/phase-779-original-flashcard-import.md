# Phase 779 证据：原版 1.4.2 闪卡导入管线（APKG/CSV/TSV/TXT）

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2`（strings.xml、`defpackage/{zf5,vf5,qpl,uf5,trl,mub}.java`）；
`decompiled_1.0.3` strings.xml 对照。
Replay：`docs/migration/replays/d02-original-flashcard-import.mjs`
ADR：`ADR-0723-original-flashcard-import.md`

## 1. 格式枚举与映射

`zf5` 枚举：`APKG / CSV / TSV / TXT / Other`；
`qpl.d()` 将请求侧 `vf5` 序数一一映射（0→APKG、1→CSV、
2→TSV、3→TXT、4→Other）。

## 2. APKG = 本地 ZIP + Anki SQLite

- `trl`/`mub`：`java.util.zip.ZipFile/ZipEntry` 直接解包；
  `mub` 对单条目设 64 MB 上限（`67108864` 守卫抛错）。
- `uf5`：目标文件白名单 `collection.anki21b /
  collection.anki21 / collection.anki2`（Anki 集合库文件名）。
- 解析簇（trl/mub/uf5/rlf）无网络调用——APKG 提取与
  CSV/TSV/TXT 切分均为**本地管线**。

## 3. 字符串族（24 键；对照 1.0.3 的 14 键 flashcard 存量）

新增键族分三层：

- 入口：`home_import_flashcards_from_anki` /
  `home_import_flashcards_manually` + 标题/副标题。
- 分隔符模型：`delimiter_{comma,semicolon,tab,new_line,custom}`
  + `between_term_and_definition` / `between_rows`
  （术语—定义、行间两级分隔）。
- 手动粘贴：`manual_instructions`（Tab/Comma 二选一）+
  `paste_example`（`Flower%1$s…%2$s…` 模板）+
  `paste_placeholder`。
- 错误/边界：`upload_failed`/`generic_error`/
  `manual_format_error`/`unsupported_file_type`/
  `quota_title`+`quota_body`（配额=订阅边界）。

## 4. 同期 Learn 新键（附带登记）

`feature_learn_quiz__flashcard_onboarding_*`（again/easy/good/
hard 四档 SM-2 评分引导）+ `ui_learn__flashcards_caught_up /
due_count_truncated`——闪卡复习评分面。

## 5. 分类结论

- **本地候选**（最高可移植性）：APKG/CSV/TSV/TXT 解析 +
  双级分隔符 + 手动粘贴——无后端依赖的纯解析管线，
  与 Phase 772 服务端 syllabus 解析形成对照。
- quota 门控：订阅边界，fail-closed 随 Learn/订阅族。
- Harmony 现状：无闪卡导入面（亦无 1.0.3 闪卡面——
  Learn 族整体后端/AI 边界内）；登记版本差。
