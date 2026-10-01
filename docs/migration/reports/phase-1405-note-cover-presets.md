# Phase 1405 报告 — 笔记封面预设（iw2/ebn/d7b/cbn.f 等价）

## 范围

原版 "Add Note Cover" 预设封面特性端到端落地：10 个捆绑 PDF 封面 +
选择器 + note_meta.cover_preset 持久化 + 库卡片封面渲染。

## 原版证据

- `iw2.java`：10 个 CoverPreset{F=covers/<key>.pdf, G=drawable,
  H=名字 res, I=类目}；`rs` case6 逐 preset SHA-512。
- `gw2` 候选 sealed：NoSelection/Preset/Custom(jwf 上传图)。
- `ebn.b`：标题 + 预览卡（封面+标题+日期）+ Presets + Cancel/Done。
- `ebn.c(bpj, m7b, done, jwf?)`：PageManager/Library/Templates 三入口。
- `d7b.b`：selectPreset → covers/<F>.pdf CAS 导入 → 封面元素媒体替换；
  note unavailable → "Cover change skipped" 短路。
- `cbn.f`：页菜单 "Add Note Cover" 行（z5&&z4，templates 图标，
  create_template 与 clear_page 之间）。

## Harmony 落点

- `rawfile/covers/`：10 PDF（416KB）。
- `NoteCoverCatalog`：NOTE_COVER_PRESETS（iw2.K 序）+
  findNoteCoverPreset + loadNoteCoverThumb（PDFKit 光栅）。
- DB v76：`note_meta.cover_preset`（base DDL + 迁移并置）；
  `NoteMeta.coverPreset`；`setNoteCoverPreset`（mutex+部分 UPDATE+
  bump updated_at）；FolderRepositoryImpl 投影同步。
- `NoteCoverSheet`：预览卡/Presets 栅格/Cancel/Done/键预选。
- `PageOverviewPanel` 页菜单行 → `NotePage` `add_cover` 截获 →
  bindSheet；apply 持久化 + 状态回写。
- `LibraryPage`：cover_preset 命中 → covers PDF 光栅；`|cover:` 入
  revision 击缓存；未知键回退页缩略图。

## 未移植（fail-closed，ADR-1341）

- ew2 自定义上传封面；m7b.Library/Templates 入口；doc 层封面元素
  （Harmony 以列投影近似）。

## 验证

- 新 fixture 68 checks；全量基线 1257/1257；双 HAP clean build 成功。
