# 原版证据：feature_library__ 族尾部 — JADX 静态审计（2026-09-25）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（JADX 反编译 Notability 1.0.3，只读证据）

## 1. 族构成（98 键）

按语义聚合：排序（9）、搜索（4）、空态（8）、多选/项操作（15）、
侧栏（8）、未索引诊断（5）、扫描件（3）、常规导航标签（≈15）、
Home 表面（11）、协作/账号绑定（≈15）。

## 2. 尾部核查点

- `sidebar_delete_folder_swipe_action`（`md.java:309`）：
  `go5.b(ue4.z(...), tl7.T(...delete_folder_swipe_action, title)...)`
  —— 侧滑删除 a11y 文案（含文件夹名插值）。Harmony 侧栏无滑动手势，
  删除经长按/编辑菜单 + 确认对话框（Phase 717/718），手势差异随
  本族登记。
- `notes_role_prompt_*`/`notes_role_info_*`：`m8`/`h3`/`ccj`
  渲染 ROLE_NOTES 默认应用提示与后续说明气泡——已在
  ADR-0661（sibling datastore keys）登记其字符串与键。
- `home_*`：`LIBRARY_HOME` 旗标开启态独有表面（Phase 706 登记；
  Harmony 为旗标关闭态经典布局）。
- `learn_card_score`/`learn_card_completed`/`learn_more`：Learn
  AI 学习卡（ADR-0652）。
- `note_limit_alert_message`/`note_limit_banner_message`/
  `note_limit_title`：账号笔记上限提示（ADR-0662）。
- `empty_shared_notes_*`/`shared`/`duplicate_not_downloaded`/
  `report_note`/`open_in_new_window`：协作与平台边界
  （ADR-0513/0662 + LibraryPage 不可移植注释）。
- `unindexed_notes`/`index_notes`/`all_notes_indexed`/
  `if_the_note_causes_the_app_to_crash…`/`copy_note_id`：
  Room FTS 索引诊断表面——Harmony `unindexedDialog` + 计数
  徽章已移植。
- `docscan`/`doc_scan_failed`/`scanned_document_title`：ML Kit
  文档扫描入口（ADR-0647）与扫描件标题模板（已落资源）。
- `scanned_document_title` = "Scanned Document %1$s" 与 Harmony
  资源逐字一致。

## 3. 结论

`feature_library__` 98 键无新增缺口：≈70 键已移植、≈28 键由
既有边界 ADR 覆盖；ADR-0671 闭合该族审计。
