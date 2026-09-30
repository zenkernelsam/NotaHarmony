# Phase 1375 证据 — 选区菜单原版图标

- 日期：2026-08-09
- 范围：`SelectionOverlay.buildSelectionMenu` 菜单项从纯文本升级为
  icon+label（`MenuElement.icon` → `selmenu_*.svg`）。
- Replay：`docs/migration/replays/d02-original-selection-menu-icons.mjs`
  （35/35）

## 原版证据（ux9.java）

原版选区菜单每个 `r68` 行均为 icon+label：`new r68(R.string.X,
new n68/o68(<drawable painter>))`。逐行确认 drawable：

- copy/cut/duplicate → `ui_designsystem__copy`/`__cut`/`__duplicate`
- group/ungroup → `ui_designsystem__group`（两项共用同一图标）
- send_forward/send_to_front → `feature_note__selection_menu_send_forward`
- send_backward/send_to_back → `feature_note__selection_menu_send_backward`
- delete → `ue4.z()` → `ui_designsystem__trash`
- edit_math/convert_to_math → `feature_note__selection_menu_convert_to_math`
- crop → `feature_note__selection_menu_crop`
- flip_horizontal/vertical → `selection_menu_flip_horizontal`/`_vertical`
- lock/unlock → `ui_designsystem__lock`/`__unlock`
- deselect → `ui_designsystem__circle_minus`
- style → `feature_note__selection_menu_style_outline`
- paste → `ui_designsystem__paste_content_manager`（无独立 `__paste`；
  PASTE 本就是 Harmony 注册适配）

## SVG 生成

`_gen_menuicons.cjs` 把 `decompiled_1.0.3` 的 16 个 drawable XML 转为
`note/src/main/resources/base/media/selmenu_*.svg`：

- 保留 `viewportWidth/Height`→`viewBox`（`lock`/`unlock` 原生 16×16）。
- 保留多 `<path>`、`<group>`+`<clip-path>`（copy 的虚线副本标记）、
  混合 stroke/fill（send_forward 的分层方块为 fill path）。
- 跳过 `M0,0h24v24h-24z` 边框 path；`fillColor="#00000000"`→`fill="none"`。

## 行为不变

菜单项 `action`/顺序/条件（canStyle/canPaste/canGroup/…）全部不动，
仅新增 `icon` 字段。`deselectMode` 的 Done/Cancel 仍无图标（k2f 操作条）。
