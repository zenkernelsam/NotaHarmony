# Phase 1402 — 捆绑模板收藏 / 最近使用 / 用量（gaf/qsh 等价）

- ADR：`docs/migration/adr/ADR-1338-template-favorites-recents.md`
- 证据：`docs/migration/evidence/phase-1402-template-favorites-recents.md`
- Replay：`docs/migration/replays/d02-original-paper-template-favorites.mjs`（48 项）

## 背景

Phase 1401 落地了图库 + 当前页应用主链路，但 cell 还只是"点选即应用"。
原版 `gaf`/`qsh` 数据面为打包模板提供三张 Room 表，驱动 cell 星标、
PRESET tab 的 Recents/Favorites 区块与会话徽记。本 Phase 补齐这套
可移植元数据层。

## 原版证据

- 建表（`ca3`）：`FavoritePaperTemplate(pdfAssetPath PK, favoritedAt)`、
  `RecentPaperTemplate(pdfAssetPath PK, usedAt)`、
  `PaperTemplateUsage(templateUuid PK, useCount)`、
  `RecentGalleryTemplate`（云端模板，Harmony 不落库）。
- 查询/裁剪（`fch`/`nsh`）：favorites `ORDER BY favoritedAt DESC`；
  recents `ORDER BY usedAt DESC` 且 `NOT IN (… LIMIT 36)` 裁剪。
- `qgc` cell：`{模板, resolvedVariant, isCurrent, isFavorite}`；
  `isCurrent` = 本会话 `a1d` 最近 Preset 变体。
- `q9l.b`/`ibn.c`：cell 右上星标 `ui_designsystem__favorite_fill`/
  `_outline`（同一星形 path；fill 实色 vs 1.25 stroke round-join）。
- 写路径：`pth.o(chc,z)` → `yb6` 收藏 upsert；`pth.t(chc)` → `qc0`
  应用成功 → recents 上移 + useCount+1。
- `s7n.d`：区块按存入 `pdfAssetPath` 精确反查 exact variant
  （不按当前页上下文重解析）。

## Harmony 实现

- `BundledTemplateMetaStore.ets`（新）：preferences `bundledPaperTemplateMeta`；
  三键 + 36 条裁剪常量 + 写失败回滚（与 EditorSettingsStore 同款）。
- `PaperTemplateCatalog.ets`：新增 `findBundledPaperVariantByPath` /
  `BundledPaperVariantMatch`（mapI0 等价）。
- `PaperTemplateGallery.ets`：`@State favoritePaths/recentPaths` +
  `aboutToAppear` 加载；cell `@Prop favorite/current` + 星形 overlay
  （stopPropagation 防误应用）+ accent 描边徽记；Recents/Favorites
  区块恒在、空态用 ria 文案。
- `NotePage.ets`：`lastAppliedBundledTemplatePath`（qgc.c 会话徽记源）
  透传图库；`applyBundledPaperTemplate` 成功后 `recordUsed(path, uuid)`
  （失败不回滚页背景，与原版 qc0/应用流分离同语义）。
- 字符串 en/zh 各 +6 键。

## 验证

- `d02-original-paper-template-favorites.mjs`：48 checks。
- `note@default` 构建成功；`note@ohosTest` clean 构建成功。
- 全量 Desktop Replay 基线见跟踪文档。

## 登记后续

- `onSetDefaultPaperTemplate`（`pth.g` → `o8b.w/x`）：默认模板消费方在
  新笔记/新页创建路径，待另行 Phase。
- Pages 作用域应用（`wgm`/`olm`/`b8f`）、`repeat_template`、
  My Templates / custom-template CRUD、covers/planners、`sth` 三 tab
  结构、`interactive_template` 语义保持登记。
