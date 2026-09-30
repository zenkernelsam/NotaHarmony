# ADR-1308: 页/区块控制按钮矢量图标 + 每字形原生 viewport

- 状态：已采纳
- 阶段：Phase 1372
- 关联：ADR-1305/1306/1307、`ToolGlyph.ets`、`ToolGlyphs.ets`

## 背景

`ToolGlyph` 的 `viewPort` 曾硬编码 `24×24`——适用于绝大多数
`ui_designsystem__*` 资源，但 `plus`(12×12)、`search`(16×17) 等非 24
矢量会被错误缩放。本阶段要移植的页/区块控制图标中恰好含这类异形
viewport，故同时把 viewport 提升为每字形数据。

## 决策

1. `ToolGlyphPaths` 增 `vw`/`vh`；`_gen_toolglyphs.cjs` 的 `read()` 记录
   每个 drawable 的 `viewportWidth/Height`，`ToolGlyph.viewPort` 改用
   `paths().vw/vh`。24×24 资源行为不变（vw=vh=24）。
2. 新增页/区块字形：
   - `add_page`（页管理 `+`，o 槽）
   - `plus`（创建 FAB `+`，o 槽，12×12）
   - `search`（页概览 content_manager_search=ue4.A，o 槽，16×17）
   - `bookmark_tall_{outline,fill}`（书签态切换；fill 进 f 槽）
   - `close_med_regular`/`close_med_bold`（关闭 ×，o 槽）

## 覆盖的占位

| 占位 | 位置 | 字形 |
|------|------|------|
| `+`(页管理) | PageManagerBar | `add_page` |
| `🔖` | PageManagerBar 书签 | `bookmark_tall_{fill,outline}` 按态切换 |
| `⚙`(compact) | PageManagerBar SettingsButton | `settings` |
| `🔍` | PageOverviewPanel | `search` |
| `×` ×4 | PageSettingsPanel×2/RecordingPanel/LibraryPage 抽屉 | `close_med_regular` |
| `+`/`×` | LibraryPage 创建 FAB | `plus`/`close_med_regular` |

## 已知近似

- 缩放 `+`/`-`（NoteCanvasView/TextBlockOverlay 缩放导航）无对应原版
  `minus`/`zoom_out`/`zoom_in` 资源，保留文本按钮——原文缩放导航用
  其他控件表达，故不强行映射。已记录。
- 书签 `bookmark_tall_fill` 的着色用 accent（原版已书签态为彩色填充），
  属合理近似。

## 验收

- `d02-original-page-section-glyphs.mjs`：28/28。
- 全量 Replay 基线：1225/1225。
- `note@default` / `note@ohosTest` clean 构建成功。
