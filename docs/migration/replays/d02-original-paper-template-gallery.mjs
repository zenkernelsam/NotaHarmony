// Phase 1401 — 原版 1.4.2 捆绑纸张模板图库。
// 原版证据（decompiled_1.4.2）：
//   resources/assets/papertemplates/ — 35 个打包目录（metadata.json
//     uuid/name/paperSizes/defaultPaperSize/colors/category[.displayIndex] +
//     <P>_<Size>_<hex6>[_orient].pdf 文件族 + thumb.(png|heic)）。
//   rgc — assets.list 遍历目录；排序 category.ordinal → displayIndex
//     (null→MAX) → name（lec byte4/5/6 比较链）。
//   zgc.b — variant 解析：末段为 portrait/landscape 才吃方向后缀；
//     hex6 需过 [0-9a-f]{6}；尺寸名经 kgc 查找；thumb 门控可见性
//     （000000 优先 thumb_black*，回退 thumb*；无对应 thumb 的变体
//     不产生 chc —— landscape 变体只在存在 *_landscape thumb 时出现）。
//   ha6 — pgc.a(size,orient,colorHex)：同 size+orient 过滤 → wp(byte17)
//     平方 RGB 距离最小 → lec(byte1) colorHex 平局决胜；null → 模板
//     不进图库（qgc 列表过滤）。
//   入口：jm4 空笔记动作面第四动作位 Templates（ui_templates__templates，
//     ui_designsystem__templates 图标）→ x2n 模板面。
//   应用：rsh.q(chc) → a1d Preset → f1d case0 → sqc.b：打包资产暂存
//     （assets → 临时文件）→ ybl.a 导入笔记资产 → sgn.e 页背景寄存器
//     （pdn.c asset+pageCount+cropBoxes+FIT_AND_CROP_BOX）。
// Harmony 落点（ADR-1337）：rawfile 打包 papertemplates/**.pdf +
// PaperTemplateCatalog 生成表 + BundledPaperTemplateApply 暂存/导入/
// 建 PageBackground.pdf + PaperTemplateGallery bindSheet（分类分节 +
// PDF 光栅化缩略图）+ 空笔记第四动作位 Templates chip。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const catalog = readFileSync('note/src/main/ets/core/model/PaperTemplateCatalog.ets', 'utf8');
const apply = readFileSync('note/src/main/ets/data/BundledPaperTemplateApply.ets', 'utf8');
const gallery = readFileSync('note/src/main/ets/ui/editor/PaperTemplateGallery.ets', 'utf8');
const page = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const en = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 目录表 ──
check(/BUNDLED_PAPER_TEMPLATES/.test(catalog), '目录表');
const dirCount = (catalog.match(/dir: '/g) ?? []).length;
check(dirCount === 35, `35 个打包目录（实际 ${dirCount}）`);
check(/uuid: '14DD41F1-29A4-4058-9560-07AD2F10BB1A'/.test(catalog), 'college_rule uuid');
check(/BundledPaperCategory\.(NOTEPADS|ACADEMIC|CREATIVE|PLANNING|SELF_CARE)/.test(catalog),
  '五类目枚举');
check(/rawfilePath: 'papertemplates\/college_rule\/College_Letter_ffffff_portrait\.pdf'/.test(catalog),
  'variant rawfile 路径');
check(/needsLightThumbInk/.test(catalog), 'thumb light-ink 标志字段');

// ── 变体解析（pgc.a 语义）──
check(/variant\.size !== size \|\| variant\.orientation !== orientation/.test(catalog),
  'size+orientation 精确过滤');
check(/dr \* dr \+ dg \* dg \+ db \* db/.test(catalog), 'wp(byte17) 平方 RGB 距离');
check(/distance === bestDistance && variant\.colorHex < best\.colorHex/.test(catalog),
  'lec(byte1) colorHex 平局决胜');
check(/hex === null \|\| hex\.length !== 6/.test(catalog), '非法 hex → null（pgc.a 前置）');

// ── 应用管线（f1d/sqc.b → sgn.e/pdn.c）──
check(/getRawFileContent\(\s*variant\.rawfilePath/.test(apply), 'rawfile 打包资产读取');
check(/assets\/pending/.test(apply) && /bundledTemplateWriteFully/.test(apply),
  'sqc.d 等价：打包资产暂存沙箱');
check(/document\.loadDocument\(stagingPath\)/.test(apply), 'PDFKit 解析');
check(/pageCount !== 1/.test(apply), '打包模板单页约束 fail-closed');
check(/sha512Digest\(bytes\)[\s\S]{0,200}?originalAssetHashBitsFromSha512/.test(apply),
  'sha512 → assetHashBits（内容寻址资产键）');
check(/storeImportedOriginalAsset\(/.test(apply), 'ybl.a 等价：资产库导入');
check(/layoutBehavior: PdfLayoutBehavior\.FIT_AND_CROP_BOX/.test(apply),
  'pdn.c FIT_AND_CROP_BOX');
check(/totalPageCount: pageCount,[\s\S]{0,80}?pagesConsumed: pageCount/.test(apply),
  '整文档寄存器：totalPageCount=pagesConsumed=1');
check(/pageOffset: 0,[\s\S]{0,60}?cropBoxes: \[\{ widthPt: widthPt/.test(apply),
  'pageOffset=0 + cropBoxes=[页尺寸]');
check(/pageInAsset: 0/.test(apply), 'pageInAsset=0');
check(/paper: null,[\s\S]{0,40}?pdf: \{/.test(apply), 'PDF 替换 paper 寄存器');

// ── 图库 UI（x2n/u7n.e + ha6 分节）──
check(/resolveBundledPaperVariant\(\s*template, this\.pageSize, this\.pageOrientation, this\.backgroundColorHex/.test(gallery),
  'wfc 上下文 variant 解析');
check(/variant === null[\s\S]{0,40}?continue/.test(gallery), '无匹配 variant → 模板隐藏');
check(/CATEGORY_TITLES/.test(gallery) && /paper_templates_cat_/.test(gallery),
  'ugc 五类目分节标题');
check(/loadBundledTemplateThumb/.test(gallery), 'PDF 光栅化缩略图');
check(/onSelectVariant\(item\.variant\)/.test(gallery), 'cell 点选 → variant 应用');

// ── 入口与宿主（jm4 第四动作位 + x2n 模板面）──
check(/empty_note_templates[\s\S]{0,400}?showTemplateGallery = true/.test(page),
  '空笔记 Templates chip → 打开图库');
check(/bindSheet\(this\.showTemplateGallery, this\.buildTemplateGallery\(\)/.test(page),
  'bindSheet 承载模板面');
check(/applyBundledPaperTemplate\(variant\)/.test(page), '宿主 apply 分发');
check(/buildBundledTemplatePageBackground\(\s*context, database, this\.noteId, variant\)/.test(page),
  'apply 注入 noteId');
check(/applied\.background = result\.background/.test(page), '落当前页 background');
check(/type: UndoableActionType\.PAGE_SETTINGS[\s\S]{0,120}?pageBefore: before,[\s\S]{0,60}?pageAfter: applied/.test(page),
  'PageSettingsAction 撤销登记（同 rotate）');
check(/this\.showTemplateGallery = false/.test(page), '应用后关闭图库');
check(/currentPaperColorHex6/.test(page), 'wfc.d 等价 hex6 上下文');

// ── 字符串 ──
for (const key of ['empty_note_templates', 'paper_templates_title',
  'paper_templates_cat_notepads', 'paper_templates_cat_academic',
  'paper_templates_cat_creative', 'paper_templates_cat_planning',
  'paper_templates_cat_self_care', 'paper_templates_empty',
  'paper_template_apply_failed']) {
  check(en.includes(`"name": "${key}"`), `en:${key}`);
  check(zh.includes(`"name": "${key}"`), `zh:${key}`);
}

console.log(`d02-original-paper-template-gallery OK — ${n} checks`);
