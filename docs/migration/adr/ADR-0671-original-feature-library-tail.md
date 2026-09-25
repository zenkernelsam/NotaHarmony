# ADR-0671 feature_library__ 族尾部收口：审计闭合登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：723
- 证据：`docs/migration/evidence/original-feature-library-tail-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-feature-library-tail.mjs`

## 背景

`feature_library__` 是原版库页字符串族（98 键）：排序、搜索、空态、
多选、文件夹侧栏、未索引诊断、扫描件、Home 表面与协作/账号绑定
项。审计确认全部键已落地或由既有边界 ADR 覆盖；本 ADR 闭合该族。

## 逐类决策

### 已移植覆盖

- 排序矩阵：`A_to_Z`/`Z_to_A`/`newest_to_oldest`/`oldest_to_newest`/
  `created_date`/`modified_date`/`name`/`sort`/`cd_sort` →
  `sort_a_to_z` 等 + `sort` 交互（库页排序菜单）。
- 搜索：`search`/`clear_search`/`search_in_folder`/
  `search_show_all_notes` → 同名资源 + 范围切换；空态
  `no_matching_notes`。
- 空态：`empty_favorite_notes_*`/`empty_recent_notes_*`/
  `empty_unfiled_notes_*`/`empty_folder_body`/
  `empty_folder_with_children_body`/`lets_get_started`/
  `tap_on_the_create_button_to_create_new_notes` → hf0/yw3 空态体系。
- 多选/项操作：`select_all`/`deselect_all`/`select_note`/
  `note_options`/`duplicate`/`favorite`/`unfavorite`/`share`/`export`/
  `export_options`/`import`/`delete`/`copy_note_id`/`show_in_folder`/
  `sort_to_folder` → 多选 + 上下文菜单各 phase。
- 侧栏：`sidebar_*`（add/collapse/delete/edit/expand/folders/
  rename/swipe_action）→ 文件夹轨道展开/折叠 + 重命名/删除对话框
  （Phase 717/718）。
- 未索引诊断：`unindexed_notes`/`index_notes`/`all_notes_indexed`/
  `if_the_note_causes_the_app_to_crash…`/`copy_note_id` → n32
  说明对话框 + 计数徽章（LibraryPage `unindexedDialog`）。
- 扫描件：`docscan`/`doc_scan_failed`/`scanned_document_title` →
  ADR-0647 ML Kit 边界 + 导入标题模板。
- 常规项：`all_notes`/`recent_notes`/`favorite_notes`/`unfiled`/
  `shared`/`notes`/`templates`/`recordings`/`home`/`back` 类标签
  → 既有资源。

### fail-closed / 平台边界（引用既有登记）

- `home_*`（11 键）：`ac4.LIBRARY_HOME` 旗标开启态 Home 表面
  （CTA 卡/Learn 卡/Record Lecture）——Harmony 为旗标关闭态
  经典库布局（Phase 706 + ADR-0658 旗标族登记）。
- `notes_role_*`（6 键）：Android `RoleManager` ROLE_NOTES
  默认应用提示——HarmonyOS 无"默认笔记应用"角色 API
  （ADR-0661 sibling-key 登记覆盖字符串与 datastore 键）。
- `learn_card_*`/`learn_more`：Learn AI 卡面（ADR-0652）。
- `note_limit_*`：账号笔记上限提示（ADR-0662）。
- `empty_shared_notes_*`/`duplicate_not_downloaded`：协作共享
  与云端下载边界（ADR-0513/0662）。
- `open_in_new_window`/`report_note`：多窗口与举报入口
  （Phase 721/LibraryPage 注释登记）。

## 结论

`feature_library__` 98 键全数归档：移植覆盖约 70 键、边界登记
约 28 键。无新增运行时代码。

## 验证

- `d02-original-feature-library-tail.mjs` 断言全绿。
- 全量 Desktop Replay 607/607；双 HAP 构建通过。
