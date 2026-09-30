# ADR-1313 — 页操作菜单项挂原版矢量图标

- Phase：1377
- 状态：Accepted（同 ADR-1311 着色待核验说明）
- 日期：2026-08-09
- 关联：ADR-1311（选区菜单图标）/ ADR-1312（库笔记菜单图标）。

## 背景

`PageManagerBar.buildPageMenu` 的页操作菜单此前是纯文本 `MenuElement`。
原版 `n9j.java`（content-manager 单页菜单）每行为 `apb.f(icon=h1a,
label)`。本 Phase 逐项挂 `MenuElement.icon` → 原版矢量。

## 图标映射（n9j → media）

| 菜单项 | 原版 drawable | media |
|--------|---------------|-------|
| cut_page | `ui_designsystem__cut` | `selmenu_cut` |
| copy_page | `ui_designsystem__copy` | `selmenu_copy` |
| paste_page | `ui_designsystem__paste_content_manager` | `selmenu_paste` |
| duplicate_page | `ui_designsystem__duplicate` | `selmenu_duplicate` |
| rotate_page | `ui_designsystem__rotate_page` | `menuicon_rotate_page` |
| clear_page | `ui_designsystem__clear_page` | `menuicon_clear_page` |
| delete_page | `ue4.z()` = `ui_designsystem__trash` | `selmenu_delete` |
| bookmark_page | `ui_designsystem__bookmark_tall_fill` | `menuicon_bookmark` |

新增 3 个 media SVG（rotate_page / clear_page / bookmark）；其余复用
Phase 1375/1376 的资源。

## 差异说明

- `move_page_earlier`/`move_page_later` 为 Harmony 迁移适配（原版页排序走
  拖拽/缩略图重排，菜单无此两项）——不带图标，刻意保留。
- `bookmark_page` 在原版是工具栏切换而非菜单项；菜单项图标取
  `bookmark_tall_fill` 保持视觉一致。
- `create_template`（`ui_designsystem__create_template`）为 INTERNAL 旗标
  项，Harmony 未实现——保持缺省。
- 着色差异同 ADR-1311（icon 按资源原样渲染，深色菜单对比度待真机核验）。

## 验证

- `d02-original-page-actions-menu-icons.mjs`：18/18。
- `note@default`/`note@ohosTest` 静态构建成功。
