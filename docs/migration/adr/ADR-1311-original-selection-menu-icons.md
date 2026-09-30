# ADR-1311 — 选区上下文菜单项挂原版矢量图标

- Phase：1375
- 状态：Accepted（含一处已知待真机核验的着色差异）
- 日期：2026-08-09
- 关联：ADR-0645（选区菜单动作全表登记）/ ADR-0586（LOCK/UNLOCK 合并）。

## 背景

`SelectionOverlay` 的选区上下文菜单此前用 `bindMenu` 的 `MenuElement`
纯文本项。原版 `ux9.java` 中每个 `r68` 菜单行都是 **icon + label**
（`n68`/`o68` 包一层 drawable painter）。本 Phase 给每个菜单项挂上
对应的原版矢量图标。

ArkUI `MenuElement.icon`（API 10+，`ResourceStr`）恰好支持每行图标；
资源用 `note/src/main/resources/base/media/selmenu_*.svg`——由
`_gen_menuicons.cjs` 从 `decompiled_1.0.3` drawable XML 逐字节转出
（多 path、`<group>`+`<clip-path>`、混合 stroke/fill 均已保留）。

## 图标映射（ux9 → selmenu_*）

| 菜单项 | 原版 drawable | selmenu_* |
|--------|---------------|-----------|
| Style | `selection_menu_style_outline` | `selmenu_style` |
| Copy | `ui_designsystem__copy` | `selmenu_copy` |
| Cut | `ui_designsystem__cut` | `selmenu_cut` |
| Duplicate | `ui_designsystem__duplicate` | `selmenu_duplicate` |
| Paste | `ui_designsystem__paste_content_manager` | `selmenu_paste` |
| Group/Ungroup | `ui_designsystem__group`（共用） | `selmenu_group` |
| SendForward/ToFront | `selection_menu_send_forward` | `selmenu_forward` |
| SendBackward/ToBack | `selection_menu_send_backward` | `selmenu_backward` |
| Delete | `ue4.z()` = `ui_designsystem__trash` | `selmenu_delete` |
| EditMath | `selection_menu_convert_to_math` | `selmenu_edit_math` |
| Crop | `selection_menu_crop` | `selmenu_crop` |
| FlipH | `selection_menu_flip_horizontal` | `selmenu_flip_h` |
| FlipV | `selection_menu_flip_vertical` | `selmenu_flip_v` |
| Lock/Unlock | `ui_designsystem__lock`/`__unlock` | `selmenu_lock`/`_unlock` |
| Deselect | `ui_designsystem__circle_minus` | `selmenu_deselect` |

`deselectMode`（k2f 确认/取消条）的 Done/Cancel 不带图标——原版该条是
confirm/cancel 操作条而非图标菜单项，保持无图标。

## 差异说明

- **着色**：原版经 `ev1` 主题给图标 painter 着色；`MenuElement.icon`
  按资源原样渲染（SVG 为 `#000`/`#444f60` 深色描边）。浅色菜单正常；
  深色菜单下图标为深色，可能存在对比度不足——**待真机核验**。若确认
  需着色，后续可改 `Menu`+`MenuItem.startIcon` 或 symbolIcon 通道。
- PASTE 为 Harmony 注册适配（原版浮动 paste chip），图标取
  `paste_content_manager` 设计系统资源；不违背 ADR-0645 的缺省登记。
- 无 `ui_designsystem__paste`，故复用 `paste_content_manager`。

## 验证

- `d02-original-selection-menu-icons.mjs`：35/35。
- `note@default` 静态构建成功（全部 `selmenu_*` 资源解析）；
  `note@ohosTest` clean 构建成功。
