# ADR-1306: 编辑器工具条操作按钮改用原版 ui_designsystem__ 动作图标

- 状态：已采纳
- 阶段：Phase 1370
- 关联：ADR-1305（tool 五层字形）、`ToolGlyph.ets`、`ToolGlyphs.ets`、
  `EditorToolbar.ets`

## 背景

Phase 1368/1369 把工具簇（pen/pencil/…）的文字按钮换成了原版 `m4f`
五层字形。但工具条上仍残留六个 **Unicode 占位字符**按钮：

| 占位 | 按钮 | 原版资源 |
|------|------|----------|
| `▦` | 页面面板开关 | `ui_designsystem__content_manager`（fp0.java，p2c RichIcon）|
| `...` | 紧凑溢出菜单 | `ui_designsystem__hamburger`（ke1.java，go5.b）|
| `⚙` | 工具箱设置 | `ui_designsystem__settings_*`（ho5.u，m4f 分层）|
| `↶` | 撤销 | `ui_designsystem__topnavundo`（p9f.java）|
| `↷` | 重做 | `ui_designsystem__topnavredo`（p9f.java）|
| `↗` | 分享 | `ui_designsystem__share`（ke1.java，go5.b）|

这些是文本字形，不是原版矢量图标——一处在意的保真缺口。

## 决策

复用 Phase 1368 引入的 `Shape + Path + viewPort(24)` `ToolGlyph`
基础设施渲染这六个动作图标，不再引入新的渲染管线。

### 单色调平面图标（go5.b ColorFilter）

`topnavundo`/`topnavredo`/`share`/`hamburger` 在原版经 `go5.b` 整体
`ColorFilter` 单色调——整个矢量按状态色着色。`ToolGlyphs` 把它们放进
`o`（outline）槽，`ToolGlyph` 的 outline 通道用 `contentColor` 描边，
等价于原版的整体 tint。撤销/重做的 enabled/disabled 仍由
`.opacity(canUndo?1:0.4)` 承担（对应原版 `t9f.c/d` 的 `c.b`/`c.d` 染色）。

### 分层图标（m4f / p2c）

- `settings` 是 `ho5.u` 注册的 `m4f`（outline/highlight/shadow/fill，
  overlay 为空），走 `rz1.c` 五层管线——`ToolGlyph` 直接适配。
- `content_manager` 是 `fp0` 注册的 `p2c` RichIcon（fill + overlay +
  default/selected 双 outline）。

## 已知近似（fail-traceable）

`content_manager` 的 `p2c` 携带 `outline_default`/`outline_selected`
两个轮廓——原版面板开合时切换轮廓。但 Harmony 工具条只收
`onTogglePagesPanel()` 回调，**未持面板开/关状态**，故当前始终渲染
`outline_default`。`content_manager_selected` 字形数据已提取入
`TOOL_GLYPHS`，待面板状态经 prop/callback 透传后接线。此近似已记录，
不阻断合并。

## 验收

- `d02-original-editor-toolbar-action-glyphs.mjs`：41/41。
- 全量 Replay 基线：1223/1223（新增 1 个 fixture）。
- `note@default` / `note@ohosTest` clean 构建成功。
