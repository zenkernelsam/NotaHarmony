# Phase 723 中文报告：`feature_library__` 族尾部收口（审计闭合）

## 范围

`feature_library__` 为原版库页字符串族（98 键）——排序、搜索、
空态、多选/项操作、文件夹侧栏、未索引诊断、扫描件标题、Home
表面与协作/账号绑定项。本 phase 对全部 98 键归类并闭合族审计。

## 原版证据

见 `docs/migration/evidence/original-feature-library-tail-jadx-2026-09-25.md`：

- `md.java:309`：侧栏滑删 a11y（`sidebar_delete_folder_swipe_action`
  含文件夹名插值）——Harmony 侧栏无滑动手势，删除经菜单+确认框，
  手势差异随族登记。
- `m8`/`h3`/`ccj`：`notes_role_*` ROLE_NOTES 默认应用提示——
  HarmonyOS 无该角色 API，随 ADR-0661 登记。
- `home_*` 11 键：`LIBRARY_HOME` 旗标开启态独有表面（Phase 706）。
- `learn_card_*`/`learn_more`、`note_limit_*`、`empty_shared_notes_*`：
  ADR-0652/0662/0513 边界。

## 审计结论（98 键归档）

- 移植覆盖 ≈70 键：排序矩阵、搜索范围、空态族、多选/项操作、
  侧栏展开折叠与对话框、未索引诊断（`unindexedDialog`）、
  `copy_note_id`/`show_in_folder`/`sort_to_folder`、
  `scanned_document_title` 逐字一致、常规导航标签。
- 边界登记 ≈28 键：`home_*`、`notes_role_*`、`learn_*`、
  `note_limit_*`、`empty_shared_notes_*`/`shared`/
  `duplicate_not_downloaded`、`report_note`/`open_in_new_window`。

## 变更

无运行时代码变更——纯审计闭合 + 边界登记 phase。

## 验证

- 新增 Replay：`docs/migration/replays/d02-original-feature-library-tail.mjs`
  （30 断言全绿）。
- 全量 Desktop Replay：607/607 全绿。
- `note@default` / `note@ohosTest` 双 HAP 构建通过（clean 后复验）。

## 涉及文件

- `docs/migration/adr/ADR-0671-original-feature-library-tail.md`
- `docs/migration/evidence/original-feature-library-tail-jadx-2026-09-25.md`
- `docs/migration/replays/d02-original-feature-library-tail.mjs`
