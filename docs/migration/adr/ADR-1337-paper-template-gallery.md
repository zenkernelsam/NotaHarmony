# ADR-1337 — 捆绑纸张模板图库（papertemplates 35 包）

- 状态：已接受
- 日期：2026-08（Phase 1401）
- 证据：`docs/migration/evidence/phase-1401-paper-template-gallery.md`
- 前置：Phase 761（pack 格式登记，ADR-0708 version-delta to-review）、
  Phase 764（custom-template schema）、Phase 769（sync fail-closed）、
  Phase 782（covers/planners 登记）、Phase 783（模板类目）
- Replay：`docs/migration/replays/d02-original-paper-template-gallery.mjs`

## 决策

落地原版 1.4.2 的打包纸张模板第一刀：**图库 + 当前页应用**。

1. `papertemplates/` 35 目录 344 份 PDF + metadata.json 原样拷入
   `resources/rawfile/papertemplates/`（23MB；HEIC/PNG thumb 不拷，
   改用 PDFKit 光栅化预览）。
2. `PaperTemplateCatalog.ets` 生成表：忠实复刻 `zgc.b` 文件名解析与
   thumb 门控（000000 优先 thumb_black*；无 thumb 的变体不进目录——
   横屏变体仅存于 7 个带 `*_landscape` thumb 的包），`rgc` 排序
   （category.ordinal → displayIndex → name）。
3. `resolveBundledPaperVariant` = `pgc.a` 等价：size+orientation 过滤 →
   平方 RGB 最近色 → colorHex 决胜 → 无匹配则模板在图库隐藏。
4. `buildBundledTemplatePageBackground` = `sqc.b`/`sgn.e` 等价：
   rawfile → 沙箱暂存 → PDFKit 取页尺寸 → sha512 内容寻址导入资产库 →
   `PageBackground.pdf`（FIT_AND_CROP_BOX、单页寄存器、paper=null）。
5. `PaperTemplateGallery`（bindSheet）：ugc 五类目分节 + 3 列栅格 +
   异步 PDF 缩略图；入口为空笔记第四动作位 Templates chip（`jm4`）。
   应用走 `PageSettingsAction` 撤销管线，作用当前页。

## 理由

- 渲染链前置条件已满足：`PdfBackgroundLoader` 在 PDF 导入/页面渲染
  路径上已验证 PDFKit 光栅化——Phase 761 登记的"PDF backing render
  chain"阻塞解除。
- 应用语义忠实：variant 按当前页 size/orientation/纸色解析
  （`wfc` 上下文），只改 `background` 寄存器，不动页尺寸与元素。
- Fail-closed：模板 PDF 必须恰为 1 页；暂存/解析/入库任一步失败
  返回 error 不落半成品背景。

## 登记差异（后续 Phase）

- 变体编辑器（`template_settings`：size/orientation/color 重选 +
  `pages` 应用范围 Current/All/自选 + `repeat_template` 新页续用）：
  Phase 1402+。
- 收藏（`onFavoritePaperTemplate`/`ui_templates__favorites`）与
  Recents、`set_as_default`：需持久层，Phase 1403+。
- My Templates（自定义模板 CRUD/`interactive_template`/`import`/
  `save_as_template`）：云同步段 fail-closed（Phase 769），本地 CRUD
  后续 Phase。
- covers/ 封面（Phase 782 已登记）、planners/、库 FAB Templates
  chip（上游 flag-gated）、`search_gallery` 搜索。
- 缩略图：原版用打包 thumb（HEIC 为主）；Harmony 以变体 PDF 首页
  光栅化替代——视觉等价，`thumbnailNeedsLightInk` 仅作登记字段。

## 验证

- 新 fixture 52 项断言；catalog 转译后运行验证（解析矩阵全对）。
- `note@default` + clean `note@ohosTest` 构建通过；全量基线绿。
