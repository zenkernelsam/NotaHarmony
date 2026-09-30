# Phase 1372 报告 — 页/区块控制按钮矢量图标 + 每字形原生 viewport

## 改动概要

剩余页/区块控制按钮的 **Unicode/emoji 占位**换成原版
`ui_designsystem__*` 矢量字形；同时修正 `ToolGlyph.viewPort`
由硬编码 24×24 改为每字形原生坐标系（vw×vh），使
`plus`(12×12)、`search`(16×17) 等非 24 资源正确缩放。

| 占位 | 位置 | 字形 |
|---|---|---|
| `+` | PageManagerBar 新增页 | `add_page` |
| `🔖` | PageManagerBar 书签 | `bookmark_tall_{fill,outline}` |
| `⚙`(compact) | PageManagerBar 页设置 | `settings` |
| `🔍` | PageOverviewPanel 搜索 | `search`(16×17) |
| `×` ×4 | 3 面板 + 库抽屉 关闭 | `close_med_regular` |
| `+`/`×` | LibraryPage 创建 FAB | `plus`(12×12)/`close_med_regular` |

## 实现

- `ToolGlyphPaths` 增 `vw`/`vh`；生成器记录 `viewportWidth/Height`；
  `viewPort` 用 `paths().vw/vh`。ToolGlyphs 现 30 键。
- 书签 `bookmark_tall_fill` 已书签态 accent 着色填充；FAB 白字形
  于 accent 圆钮。
- 全部保留 onClick/enabled/opacity/a11y/状态着色。

## 文件

- `note/src/main/ets/ui/components/{ToolGlyphs,ToolGlyph}.ets`
- `note/src/main/ets/ui/editor/{PageManagerBar,PageOverviewPanel,RecordingPanel}.ets`
- `note/src/main/ets/ui/components/PageSettingsPanel.ets`
- `note/src/main/ets/ui/library/LibraryPage.ets`
- `docs/migration/replays/d02-original-page-section-glyphs.mjs`（新）
- `docs/migration/adr/ADR-1308-page-section-glyphs-and-native-viewport.md`（新）
- `docs/migration/evidence/phase-1372-page-section-glyphs.md`（新）

## 验证

- 新 fixture：28/28。
- 全量 Replay 基线：1225/1225。
- `note@default` / `note@ohosTest` clean 构建成功。

## 已知近似

- 缩放 `+`/`-`（缩放导航）无原版 `minus`/`zoom_*` 资源，保留文本
  （ADR-1308）。
