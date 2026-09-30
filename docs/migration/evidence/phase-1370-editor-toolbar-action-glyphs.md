# Phase 1370 — 编辑器工具条操作按钮改用原版矢量动作图标

## 原版证据（decompiled_1.0.3）

| Harmony 占位 | 原版资源 | 注册/渲染 | 证据类 |
|---|---|---|---|
| `▦` 页面面板 | `ui_designsystem__content_manager_{fill,overlay,outline_default,outline_selected}` | `p2c` RichIcon | `fp0.java` |
| `...` 紧凑溢出 | `ui_designsystem__hamburger` | `go5.b` 单色 tint | `ke1.java` |
| `⚙` 工具箱设置 | `ui_designsystem__settings_{fill,outline,highlight,shadow}` | `m4f` → `rz1.c` | `ho5.java`（`ho5.u`）|
| `↶` 撤销 | `ui_designsystem__topnavundo` | `go5.b`，`t9f.c/d` 按 canUndo 染 `c.b`/`c.d` | `p9f.java` |
| `↷` 重做 | `ui_designsystem__topnavredo` | 同上 | `p9f.java` |
| `↗` 分享 | `ui_designsystem__share` | `go5.b` 单色 tint | `ke1.java` |

资源路径：`decompiled_1.0.3/resources/res/drawable/`。

## Harmony 实现

- `_gen_toolglyphs.cjs` 的 `T` 映射追加 7 个动作字形键：
  `topnavundo`、`topnavredo`、`share`、`hamburger`、`settings`、
  `content_manager`、`content_manager_selected`。
- `ToolGlyphs.ets` 重新生成，现 18 个键（11 tool + 7 action）。
  - 平面单色调（go5.b）：矢量进 `o` 槽，`contentColor` 描边。
  - `settings`：`f`/`o`/`h`/`s` 四层（m4f，`d`/overlay 空）。
  - `content_manager`：`f`/`o`/`v` 三层（p2c）+ `_selected` 变体。
- `EditorToolbar.ets` 六个占位 `Button('…')` 全部换成
  `Button(){ ToolGlyph({glyph:…, contentColor, dark, iconSize}) }`。
  点击、`enabled`、`.opacity(canUndo/canRedo)`、`bindPopup`、
  `bindMenu`、全部 `accessibilityText` 原样保留。

## 已知近似

`content_manager` 面板开/关的 selected 轮廓未接线（工具条无面板状态
prop）——见 ADR-1306。

## 验证

- `d02-original-editor-toolbar-action-glyphs.mjs`：41/41。
- 全量 Replay：1223/1223。
- `note@default` / `note@ohosTest` clean 构建成功（仅预存在告警）。
