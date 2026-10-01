# ADR-1338 — 捆绑模板收藏 / 最近使用 / 用量

- 状态：已接受
- 日期：2026-08（Phase 1402）
- 证据：`docs/migration/evidence/phase-1402-template-favorites-recents.md`
- 前置：ADR-1337（图库 + 当前页应用）
- Replay：`docs/migration/replays/d02-original-paper-template-favorites.mjs`

## 决策

落地原版 `gaf`/`qsh` 元数据面的可移植子集：**收藏 + 最近使用 + 用量计数**。

1. `BundledTemplateMetaStore`（preferences 持久化）对应三张 Room 表：
   - `favoritePaperTemplates` ↔ `FavoritePaperTemplate`（pdfAssetPath 主键，
     `ORDER BY favoritedAt DESC` → 有序数组首项为最近收藏）；
   - `recentPaperTemplates` ↔ `RecentPaperTemplate`（`ORDER BY usedAt DESC`，
     写入后按 `nsh` case110 同款 `LIMIT 36` 裁剪）；
   - `paperTemplateUsage` ↔ `PaperTemplateUsage`（uuid → useCount 映射）。
   键语义：原版 `chc.e` = pdfAssetPath ↔ Harmony `rawfilePath`；
   `chc.a` = templateUuid ↔ `BundledPaperTemplate.uuid`。
2. `pth.o(chc,z)` → `yb6` 收藏写等价：`setFavorite(path,z)`；cell 星标
   `ui_designsystem__favorite_fill`/`_outline`（星形 path：fill 实色 vs
   透明 fill + 1.25px stroke round-join evenOdd）置于缩略图右上。
3. `pth.t(chc)` → `qc0` 应用记录等价：`recordUsed(path,uuid)` 在
   `applyBundledPaperTemplate` 成功后触发（recents 上移 + 36 裁剪 +
   useCount+1），失败不回滚已应用的页背景。
4. 图库顶部新增 Recents / Favorites 两区块（`ui_templates__recents`/
   `favorites` 标题 + `ria` 空态文案），按存储序渲染存入的
   exact variant（`findBundledPaperVariantByPath`，s7n.d/mapI0 等价，
   不按当前页上下文重解析）。
5. `qgc.c` 会话徽记：`NotePage.lastAppliedBundledTemplatePath` 记录本会话
   最近 Preset 应用的变体路径，cell 以 accent 描边徽记。

## 布局差异（版本差异登记）

- 原版 recents/favorites 挂 `sth.PRESET` tab（`qia{a,b}`），与四个内置
  纸型（PLAIN/LINES/GRID/DOTS）同屏；Harmony 的 PRESET 语义已分布在
  PageSettingsPanel，故本切片将 Recents/Favorites 作为统一分节列表的
  置顶区块。区块标题、空态文案、排序、裁剪上限逐项对齐原版。

## Fail-closed / 登记项

- `RecentGalleryTemplate`（云端模板 noteId/title/likes/downloads/…）：
  Harmony 无云端图库 → 不落库。
- `onSetDefaultPaperTemplate`（`pth.g` → `o8b.w/x` flatbuffer `pfc` +
  uuid）：默认模板消费方在新笔记/新页创建路径，另行 Phase。
- Pages 作用域应用（`wgm`/`olm`/`b8f`：`current|all|select_pages`）、
  `repeat_template`、My Templates/custom-template CRUD、covers/planners、
  `interactive_template` 语义保持登记。

## 验证

- `d02-original-paper-template-favorites.mjs`：48 checks。
- 全量 Replay 基线 + `note@default`/`note@ohosTest` 构建（见报告）。
