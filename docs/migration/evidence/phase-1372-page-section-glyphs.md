# Phase 1372 — 页/区块控制按钮矢量图标 + 每字形原生 viewport

## 原版证据（decompiled_1.0.3）

`ue4.java` 图标提供者 + `ui_designsystem__*` 资源：

| 占位 | 原版资源 | viewport | 槽位 | 证据 |
|---|---|---|---|---|
| `+` 新增页 | `add_page` | 24×24 | o | PageManagerBar |
| `+`/`×` FAB | `plus`(12×12)/`close_med_regular` | 12 / 24 | o / o | `ue4.u` |
| `🔖` 书签 | `bookmark_tall_{outline,fill}` | 24 | o / f | 状态切换 |
| `🔍` 搜索 | `search`（content_manager_search）| 16×17 | o | `ue4.A`/`r22` case24 |
| `⚙` 页设置(compact) | `settings_*`（ho5.u m4f）| 24 | f/o/h/s | `ho5.java` |
| `×` 关闭 ×4 | `close_med_regular` | 24 | o | `ue4.u` |

## 关键修正：每字形 viewport

`ToolGlyph.viewPort` 原硬编码 `24×24`；`plus`(12×12)、`search`(16×17)
会被缩错。`ToolGlyphPaths` 增 `vw`/`vh`，`_gen_toolglyphs.cjs` 记录
`viewportWidth/Height`（o 槽优先，无 o 取 f），`viewPort` 改用
`paths().vw/vh`。24×24 资源行为不变。

## Harmony 实现

`ToolGlyphs.ets` 现 30 键。`read()` 的 bounding-box 过滤升级为通用
`M0,?0.5?h<v>v<h>h-<v>z` 形式（覆盖 16/17/24 任意 frame）。

替换位置（均保留 onClick/enabled/bindMenu/a11y/状态着色）：
- `PageManagerBar`：`+`→`add_page`、`🔖`→`bookmark_tall_*`、紧凑 `⚙`→`settings`
- `PageOverviewPanel`：`🔍`→`search`（active 态 accent 着色保留）
- `PageSettingsPanel`：×2 `×`→`close_med_regular`
- `RecordingPanel`/`LibraryPage` 抽屉：`×`→`close_med_regular`
- `LibraryPage` FAB：`+`/`×`→`plus`/`close_med_regular`

## 已知近似

- 缩放 `+`/`-`（缩放导航）无原版对应资源，保留文本（ADR-1308）。
- `🔖` 已书签态用 accent 着色填充（近似原版彩色态）。

## 验证

- `d02-original-page-section-glyphs.mjs`：28/28。
- 全量 Replay：1225/1225。
- `note@default` / `note@ohosTest` clean 构建成功。
