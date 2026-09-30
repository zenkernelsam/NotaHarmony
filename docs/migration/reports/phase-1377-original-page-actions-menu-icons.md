# Phase 1377 报告 — 页操作菜单挂原版矢量图标

- 日期：2026-08-09
- 结果：完成；`note@default` 与 `note@ohosTest` 静态构建成功。
- ADR：`ADR-1313-original-page-actions-menu-icons.md`
- 证据：`phase-1377-original-page-actions-menu-icons.md`
- Replay：`d02-original-page-actions-menu-icons.mjs`（18/18）

## 本 Phase 做了什么

把 `PageManagerBar.buildPageMenu` 页操作菜单项从纯文本升级为 icon+label，
逐项挂 `MenuElement.icon` → 原版矢量（复刻 `n9j`）。

## 改动文件

- `_gen_menuicons.cjs`：追加 `menuicon_{rotate_page,clear_page,bookmark}`。
- `note/src/main/resources/base/media/menuicon_{rotate_page,clear_page,
  bookmark}.svg`：新增 3 个。
- `note/src/main/ets/ui/editor/PageManagerBar.ets`：bookmark/cut/copy/
  paste(splice)/duplicate/rotate/clear/delete 加 `icon`；move_earlier/
  move_later 为 Harmony 适配不带图标。

## 验证

- `d02-original-page-actions-menu-icons.mjs`：18/18。
- `note@default`/`note@ohosTest` 静态构建成功。
- 全量 Desktop Replay 基线：全绿。
