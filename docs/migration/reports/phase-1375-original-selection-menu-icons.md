# Phase 1375 报告 — 选区上下文菜单项挂原版矢量图标

- 日期：2026-08-09
- 结果：完成；`note@default` 与 `note@ohosTest` 静态构建成功。
- ADR：`ADR-1311-original-selection-menu-icons.md`
- 证据：`phase-1375-original-selection-menu-icons.md`
- Replay：`d02-original-selection-menu-icons.mjs`（35/35）

## 本 Phase 做了什么

把 `SelectionOverlay` 选区上下文菜单从纯文本项升级为原版 icon+label
行——逐项挂 `MenuElement.icon` → 原版 `selection_menu_*` /
`ui_designsystem__*` 矢量的 SVG 副本。

## 改动文件

- `_gen_menuicons.cjs`：新增 drawable→SVG 转换器（多 path/group/
  clip-path/混合 stroke+fill），产出 16 个 `selmenu_*.svg`。
- `note/src/main/resources/base/media/selmenu_{style,copy,cut,duplicate,
  paste,group,forward,backward,delete,edit_math,crop,flip_h,flip_v,lock,
  unlock,deselect}.svg`：新增 16 个矢量媒体资源。
- `note/src/main/ets/ui/components/SelectionOverlay.ets`：每个
  `MenuElement` 增加 `icon: $r('app.media.selmenu_*')`；group/ungroup、
  send_forward/to_front、send_backward/to_back、lock/unlock 按原版共用/
  条件切换同一矢量。

## 差异

- `MenuElement.icon` 按资源原样渲染，未经主题着色；深色菜单下深色描边
  图标对比度待真机核验（ADR-1311）。
- PASTE 无独立原版图标，取 `paste_content_manager`（该项本就是 Harmony
  注册适配）。

## 验证

- `d02-original-selection-menu-icons.mjs`：35/35。
- `note@default` clean 构建：成功。
- `note@ohosTest` clean 构建：成功。
- 全量 Desktop Replay 基线：全绿。
