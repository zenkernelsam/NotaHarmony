# Phase 1401 — 捆绑纸张模板图库（bundled paper templates）

## 原版证据（decompiled_1.4.2）

### 资产包（Phase 761 已登记格式）

`resources/assets/papertemplates/`：35 个目录，每目录：

- `metadata.json`：`uuid` / `name` / `paperSizes[]` / `defaultPaperSize` /
  `colors[]`（hex）/ `category`（notepads|academic|creative|planning|selfCare）
  / 可选 `displayIndex`。
- `<Prefix>_<Size>_<hex6>[_portrait|_landscape].pdf` 文件族（共 344 份）。
- `thumb[...].[heic|png]` 预览图族。

### 目录装载（rgc → zgc.b）

`rgc` 用 `context.getAssets().list("papertemplates")` 遍历目录，逐目录读
`metadata.json` 调 `zgc.b(dir, fileList, json)` 建 `pgc`（模板聚合），产物经
`sgn.u(lec4, lec5, lec6)` 排序：**category.ordinal → displayIndex(缺省→MAX) → name**。

`zgc.b` variant 解析：

- 文件名 `_` 拆分；末段 `landscape`/`portrait` 判定方向（无后缀→PORTRAIT），
  前一段为 hex6（须过 `[0-9a-f]{6}`），再前一段为尺寸名（`kgc` 名称表）。
- **thumb 门控**：每变体必须有对应 thumb 文件（hex==000000 优先
  `thumb_black[_landscape]`，回退 `thumb[_landscape]`）——无 thumb 的变体
  不产生 `chc`。净效果：仅 7 个含 `*_landscape` thumb 的包存在横屏变体。
- `thumbnailNeedsLightInk = 选中常规 thumb && hex==000000`。

### 图库状态（ha6）

`pgc.a(size, orientation, colorHex)` 为**当前页上下文**解析变体：
同 size+orientation 过滤 → `wp(byte17)` 平方 RGB 距离最小 → `lec(byte1)`
colorHex 平局决胜；返回 null 的模板不进 `qgc` 列表（图库隐藏）。

### 入口与应用

- `jm4`：空笔记动作面 `Record/Import/Scan/**Templates**/Capture?`，第四
  动作位（无 flag）→ `x2n`/`u7n.e` 模板面（标题 `ui_templates__templates`）。
- `rsh.q(chc)` → `a1d(Preset)` → `f1d` case0 → `sqc.b`：资产暂存
  （`sqc.d` 打包资产拷临时文件）→ `ybl.a` 导入笔记资产 → `sgn.e` 组装页
  背景更新（`pdn.c`：asset + pageCount + cropBoxes + `FIT_AND_CROP_BOX`）。

## Harmony 落点

- `resources/rawfile/papertemplates/`：344 PDF + 35 metadata.json
  （按原样拷贝，23MB；thumb 未拷贝——Harmony 以 PDFKit 页光栅化替代）。
- `core/model/PaperTemplateCatalog.ets`（生成）：35 模板 / 344 变体表 +
  `resolveBundledPaperVariant`（pgc.a 等价：size+orient 精确过滤、平方 RGB
  最近色、colorHex 决胜、非法 hex → null）+ `BundledPaperCategory`（ugc 序）。
- `data/BundledPaperTemplateApply.ets`：rawfile → `assets/pending` 暂存 →
  PDFKit 解析（单页约束 fail-closed）→ sha512→assetHashBits →
  `storeImportedOriginalAsset` → `PageBackground.pdf`
  （FIT_AND_CROP_BOX / totalPageCount=pagesConsumed=1 / pageOffset=0 /
  cropBoxes=[页尺寸] / pageInAsset=0，paper=null）。
- `ui/editor/PaperTemplateGallery.ets`：bindSheet 图库——五类目分节、
  3 列栅格、`BundledTemplateCell` 异步光栅化缩略图（generation 防串代，
  aboutToDisappear 释放 PixelMap）。
- `NotePage`：`empty_note_templates` chip（第四动作位，capture 之前）+
  `showTemplateGallery` + `buildTemplateGallery()`（wfc 上下文注入：
  当前页 size/orientation + `currentPaperColorHex6` paper→note→ffffff
  回退）+ `applyBundledPaperTemplate`（clonePageInfo → background 替换 →
  `PageSettingsAction` 撤销 → updatePage → 关闭图库）。

## 登记差异 / 后续 Phase

- 变体编辑器（尺寸/颜色/方向 picker + 应用范围 Current/All/选择页 +
  `repeat_template`）：Phase 1402+。
- 收藏 / Recents / `set_as_default`：Phase 1403+。
- My Templates（save_as_template / interactive_template 可编辑对象
  vs 背景图开关 / import / template_refused 云同步）：同步部分
  fail-closed（Phase 769 已登记 sync worker）；本地 CRUD 后续 Phase。
- 封面（covers/ 10 PDF）、planners/、库 FAB 模板项（上游 flag-gated）。
- `thumbnailNeedsLightInk` 已入模型但缩略图改为光栅化渲染后仅作登记。
- 无匹配变体的页面上下文（如 A6/A7 页或横屏缺 thumb 包）→ 模板不显示
  （与原版 `pgc.a == null` 过滤一致）；全类目空时显示空态文案。

## 验证

- `d02-original-paper-template-gallery.mjs`：52 项断言。
- `resolveBundledPaperVariant` 转译运行验证：Letter/Portrait/ffffff 35/35
  可解析；A4/Landscape 恰好 7 包（横屏 thumb 门控一致）；f8f1b0→f8f1bf、
  111111→000000 最近色正确；非法 hex / 无尺寸变体 → null。
- `note@default` / clean `note@ohosTest` BUILD SUCCESSFUL；基线绿。
