# 原版编辑器 ⋮ 选项菜单 — Harmony 证据文档

- 日期：2026-09-22
- Phase：573
- 结论：已对齐（无条件项 App settings 完整移植；4 个旗标/状态项
  fail-closed 不移植）

## 原版证据（decompiled_1.0.3）

### ⋮ 按钮与菜单装配 `rh8` / `x90` / `ke1`

- `x90.java:10582`：`rh8.f(...)` 在编辑器工具行中**无条件调用**——
  ⋮ 溢出按钮在生产构建始终可见，位于分享/录制徽标等尾端按钮之后。
- `rh8.java:1504`：按钮图标 `ui_designsystem__hamburger`，无障碍
  描述 `feature_note__toolbar_more_menu` = "More options"
  （`strings.xml:540`）；`apb.d` 包裹下拉菜单。
- `ke1.java:32`：同一 hamburger + `toolbar_more_menu` 组合在另一
  上下文复用，佐证该字符串是 ⋮ 入口的固定无障碍标签。

### 菜单项组成 `rh8.java:1530~1600`

| 项 | 资源 | 门控 | 结论 |
|---|---|---|---|
| Template settings | `ui_templates__template_settings` | `lc4.a(ac4.P)` = TEMPLATE_SELECTION，`zb4.L` PRODUCTION + 远端键 `wtb.c`（androidTemplateSelection） | Harmony 无模板设置屏，fail-closed |
| Version history | `options_menu_version_history` | `lc4.a(ac4.d0)` = VERSION_HISTORY，PRODUCTION + 远端键 `ytb.c`（androidVersionHistory） | 史诗级特性，fail-closed |
| **App settings** | `options_menu_app_settings` | **无**（`rh8.java:1563` `apb.f` 直接渲染） | **已移植** |
| Inky | `options_menu_inky` | 调用方参数 `sc9.j`（运行时状态） | AI 吉祥物，无对应面 |
| Disconnect stylus | `options_menu_disconnect_stylus` | 调用方参数 `t9f.e`/`t9f.f`（手写笔连接状态） | 无手写笔连接面 |

- `ac4.java:95-96`：`P` = `TEMPLATE_SELECTION`，`zb4.L` =
  PRODUCTION（`zb4.java:14`），远端默认 `wtb.c`。
- `ac4.java:123-124`：`d0` = `VERSION_HISTORY`，PRODUCTION +
  `ytb.c`（androidVersionHistory）。
- 早期排查曾误记该菜单整体受 INTERNAL_USERS_ONLY 门控——实为
  `ac4.O0` = `NOTE_YOUTUBE_TRANSCRIPTION`（`ac4.java:201-203`，
  `zb4.K`）控制的是工具行中另一个内部按钮（`cq.c`），与 ⋮ 菜单
  无关；本 Phase 已纠正该结论。

### 调用方参数（`x90.java:10582`）

`rh8.f(function11, function2, function6, z13, function4, z4, j,
ix4Var7, z14, z15, ix4Var14, ...)`：

- `function2` → Version history onClick；`function6` → **App
  settings onClick**；`function4` → Disconnect stylus onClick；
  `function11` → 菜单展开 toggle。
- `z13 = sc9Var2.j` → Inky 可见性；`z4` → Inky 选中态。
- `z14 = t9f.e` → Disconnect stylus 可见性；`z15 = t9f.f` →
  Disconnect stylus 可用态。
- `ix4Var14 = xv5(...,"onInkyModeToggle",...)` → Inky 切换回调。

## Harmony 实现

- `NotePage.ets` 顶部导航行：Recordings 按钮之后新增 `...` 按钮，
  `accessibilityText($r('app.string.toolbar_more_menu'))`，
  `.bindMenu(this.buildEditorOptionsMenu())`，enabled 守卫与
  Recordings 一致。
- `buildEditorOptionsMenu()`：单元素
  `options_menu_app_settings` → `navigateToSettings()`。
- `navigateToSettings()`：
  `router.pushUrl({ url: 'ui/settings/SettingsPage' })`，与
  `LibraryPage.navigateToSettings` 同路由；守卫
  `photoImportLeaseActive / pageLoadFailed / pageLoading /
  editorDisposed`；pushUrl 失败 `console.error` 落日志。
- 资源：`options_menu_app_settings` = "App settings" / "应用设置"，
  与原版 `strings.xml:504` 逐字一致。

## 验证

- Replay：`d02-original-editor-options-menu.mjs`（28/28）。
- 全量 Desktop Replay：468/468。
- `note@default`、`note@ohosTest` HAP 构建成功。

## 局限

- Template settings / Version history / Inky / Disconnect stylus
  四项未移植，见 ADR-0544；后续若补远端旗标或对应屏，需回到
  本表补齐菜单项顺序（原版顺序：Template settings → Version
  history → App settings → Inky → Disconnect stylus）。
