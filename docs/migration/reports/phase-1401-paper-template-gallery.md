# Phase 1401 — 原版 1.4.2 捆绑纸张模板图库（第一刀）

- ADR：`docs/migration/adr/ADR-1337-paper-template-gallery.md`
- 证据：`docs/migration/evidence/phase-1401-paper-template-gallery.md`
- Replay：`docs/migration/replays/d02-original-paper-template-gallery.mjs`（52 项）

## 背景

原版 1.4.2 自带 `assets/papertemplates/` 35 包 344 份 PDF 模板
（notepads/academic/creative/planning/selfCare 五类）。Phase 761 登记了
包格式，因缺 PDF 渲染链挂 to-review；`PdfBackgroundLoader` 已在导入/渲染
路径验证 PDFKit——阻塞解除。本 Phase 落地"图库 + 当前页应用"主链路。

## 原版证据

- `zgc.b`：`<P>_<Size>_<hex6>[_orient].pdf` 解析 + thumb 门控
  （无对应 thumb 的变体不产生；横屏变体仅存于 7 个含 `*_landscape`
  thumb 的包）。
- `rgc` 排序：category.ordinal → displayIndex(缺省→MAX) → name。
- `pgc.a`：当前页 size+orientation 过滤 → 平方 RGB 最近色 → colorHex 决胜；
  null → 模板不入图库。
- `jm4`：空笔记第四动作位 Templates → `x2n` 模板面。
- `rsh.q` → `a1d` → `f1d`/`sqc.b`：打包资产暂存 → 导入资产库 →
  `sgn.e` 页背景（`pdn.c` FIT_AND_CROP_BOX）。

## Harmony 实现

- `rawfile/papertemplates/`：344 PDF + 35 metadata.json（23MB）。
- `PaperTemplateCatalog.ets`（生成）：模板/变体表 + `pgc.a` 等价解析器。
- `BundledPaperTemplateApply.ets`：rawfile→暂存→PDFKit→资产入库→
  `PageBackground.pdf`；缩略图走 `getPagePixelMap` 光栅化。
- `PaperTemplateGallery.ets`：bindSheet 五类目分节栅格；
  `empty_note_templates` chip 接入空笔记动作面；应用落当前页并入撤销
  历史（PAGE_SETTINGS）。

## 登记后续

变体编辑器 / 页范围选择 / repeat-template / 收藏/最近/默认 /
My Templates 本地 CRUD / covers / planners / 图库搜索 —— 见 ADR-1337。

## 验证

- fixture 52/52；catalog 转译运行验证（35/35 Letter 解析、7 包横屏、
  最近色、非法 hex→null）。
- `note@default` / clean `note@ohosTest` BUILD SUCCESSFUL；基线绿。
