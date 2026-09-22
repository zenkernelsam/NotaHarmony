# ADR-0544：原版编辑器 ⋮ 选项菜单（App settings 入口）

## 状态

已实施（Phase 573）

## 背景

原版笔记编辑器工具行尾端无条件渲染一枚 ⋮（hamburger）溢出按钮
（`x90.java:10582` 无条件调用 `rh8.f`），无障碍描述为
`feature_note__toolbar_more_menu` = "More options"
（`strings.xml:540`）。下拉菜单（`rh8.java:1504~1600`，`apb.d`
下拉 + `apb.f` 菜单项）按以下结构组成：

1. **Template settings** — `lc4.a(ac4.P)` 旗标包裹；
   `ac4.P` = `TEMPLATE_SELECTION`（`ac4.java:95`，`zb4.L` =
   PRODUCTION，远端键 `wtb.c` = "androidTemplateSelection"）。
   Harmony 无模板设置屏，对应能力未移植。
2. **Version history** — `lc4.a(ac4.d0)` 旗标包裹；
   `ac4.d0` = `VERSION_HISTORY`（`ac4.java:123`，PRODUCTION，
   远端键 `ytb.c` = "androidVersionHistory"）。属史诗级特性。
3. **App settings** — `rh8.java:1563` 处 `apb.f` 调用无任何
   旗标/参数包裹，**生产构建无条件可见**，跳转应用设置页。
4. **Inky** — 由 `sc9Var2.j` 运行时状态门控（`options_menu_inky`），
   为 AI 吉祥物入口，Harmony 无对应基础设施。
5. **Disconnect stylus** — 由 `t9f.e`/`t9f.f` 手写笔连接状态门控
   （`options_menu_disconnect_stylus`），Harmony 无手写笔连接面。

Harmony 编辑器此前完全没有溢出菜单：顶部导航行只有
Back / 标题 / 录制徽标 / Recordings；`EditorToolbar` 的 `...`
按钮是紧凑模式工具选择器（`buildCompactToolMenu`），与原版选项
菜单不是同一面。

## 决策

1. `NotePage` 顶部导航行在 Recordings 之后新增 `...` 按钮，
   `accessibilityText` 复用 `toolbar_more_menu`（"More options"），
   `bindMenu` 绑 `buildEditorOptionsMenu()`；enabled 守卫与
   Recordings 按钮一致（`!pageLoading && !pageLoadFailed &&
   !photoImportLeaseActive`）。
2. 菜单只移植无条件项 "App settings"（`options_menu_app_settings`，
   EN "App settings" / zh "应用设置"），动作
   `navigateToSettings()` → `router.pushUrl('ui/settings/SettingsPage')`，
   与 LibraryPage 的设置入口同一路由，守卫补 `editorDisposed`。
3. 其余四项 fail-closed 不移植：Template settings / Version history
   是远端旗标项且 Harmony 无对应屏；Inky / Disconnect stylus 依赖
   Harmony 不存在的运行时状态面。菜单中不出现占位/禁用项——
   原版旗标关闭时该项整体不渲染，而不是灰显。

## 差异

- 原版按钮为 hamburger 矢量图标，Harmony 复用本工程惯例的
  文本按钮 `'...'`（与 PageManagerBar 的 more-actions 一致）。
- 旗标项缺失导致菜单视觉更短；属主动 fail-closed，非缺陷。
- 点击态/弹窗锚点等交互观感仅真机可验（见 Phase 571 清单）。
