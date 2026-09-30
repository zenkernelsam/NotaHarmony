# Phase 1377 证据 — 页操作菜单原版图标

- 日期：2026-08-09
- 范围：`PageManagerBar.buildPageMenu` 页操作菜单项增加
  `MenuElement.icon` → 原版矢量。
- Replay：`docs/migration/replays/d02-original-page-actions-menu-icons.mjs`
  （18/18）

## 原版证据（n9j.java）

content-manager 单页菜单每行为 `apb.f(icon=h1a, label)`。逐项确认 drawable：

- add_page → `ui_designsystem__add_page`
- cut → `ui_designsystem__cut`
- copy → `ui_designsystem__copy`
- paste → `ui_designsystem__paste_content_manager`
- duplicate → `ui_designsystem__duplicate`
- rotate_page → `ui_designsystem__rotate_page`
- create_template → `ui_designsystem__create_template`（INTERNAL 旗标，未实现）
- clear_page → `ui_designsystem__clear_page`
- delete → `ue4.z()` = `ui_designsystem__trash`

## 新增资源

`_gen_menuicons.cjs` 追加 `menuicon_rotate_page` / `menuicon_clear_page` /
`menuicon_bookmark`（bookmark_tall_fill），输出到 `base/media/`。
cut/copy/paste/duplicate/delete 复用 `selmenu_*` 资源。

## 适配说明

- `move_page_earlier`/`move_page_later` 是 Harmony 迁移适配（原版页排序走
  拖拽），无原版图标——刻意不带 icon。
- `paste_page` 保持原版 `mg2.b != null` 的按需 splice 位置（Copy 与
  Duplicate 之间），仅补 `icon` 字段。
