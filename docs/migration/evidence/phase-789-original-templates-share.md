# Phase 789 证据：原版 1.4.2 模板管理器面 + 分享面板差

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2` strings.xml（`ui_templates__` 45 键、
`ui_share__` 35 键）；Harmony `LibraryPage.ets` 对照。
Replay：`docs/migration/replays/d02-original-templates-share.mjs`
ADR：`ADR-0733-original-templates-share.md`
上游：Phase 764（interactive 列）、Phase 774（gallery）、
Phase 674（多选分享已移植）

## 1. 模板管理器面（ui_templates__：1.0.3 存量 → 1.4.2 扩 45 键）

1.0.3 已有 basic_templates/my_templates/favorite 等选择器键
（Harmony 模板选择器即移植自此）；1.4.2 扩展为完整管理器：

- 页签：`basic_templates`/`my_templates`/`favorites`/recents
  （`no_recents`="Designs you apply show up here."）。
- **interactive 语义钉**（解开 Phase 764 `interactive` 列）：
  `interactive_template_on`="Objects (e.g. text, ink) will be
  editable"；`interactive_template_off`="This template will be
  a note background image"——交互式=对象可编辑，非交互=
  背景图扁平化。
- 操作：`new_template`/`edit`/`import`/`edit_note_cover`/
  `delete_template`+`_confirm`（"Notes you already made from
  this template won't change."）/`clear_template_name`。
- 外观：`background_color`/`grid_spacing`/`all_pages`/`current`/
  `go_to`/`gallery` 入口。

## 2. 分享面板差（ui_share__：1.0.3=55 → 1.4.2=35 新增）

- 五格式 chips（JPG/PNG/PDF/Note/Link；link 无 multi）为
  1.0.3 存量——**Harmony 已对齐**（Phase 674）。
- 1.4.2 新增仅为 `gallery_*` 发布段：`gallery_add_tag`/
  `gallery_convert_to_template`（"Turn your note into a single
  page background image"=发布路径把笔记转模板）/
  `gallery_clear_title`——接 Phase 774 后端面。

## 3. 分类结论

- 模板管理器（interactive 语义/页签/导入/删除）：版本差·
  本地候选——自建模板 CRUD 无后端。
- ui_share__ 主体：已对齐；gallery_* 段随 774 边界。
- Harmony 现状：无模板管理器面（自定义模板整体版本差）。
