// Phase 1402 — 原版 1.4.2 捆绑模板收藏/最近使用/用量（gaf/qsh Room 表等价）。
// 原版证据（decompiled_1.4.2）：
//   qsh/lye Room 表（ca3 建表语句）：
//     FavoritePaperTemplate(pdfAssetPath PK, favoritedAt) — SELECT 按
//       favoritedAt DESC（fch case 194）；
//     RecentPaperTemplate(pdfAssetPath PK, usedAt) — SELECT 按 usedAt DESC
//       （nsh case 76），并经 DELETE … NOT IN (ORDER BY usedAt DESC LIMIT 36)
//       裁剪（nsh case 110）；
//     PaperTemplateUsage(templateUuid PK, useCount) — nsh case 93；
//     RecentGalleryTemplate —— 云端图库表（noteId/title/likes/…），
//       Harmony 无云端图库 → fail-closed 不落库。
//   ha6 case default：list4(recents)→s7n.d(mapI0, appliedVariant, favSet,
//     pdfAssetPath) 按存入路径精确反查 chc；qgc{pgc, chc, isCurrent, isFav}。
//   q9l.b cell：chc.e pdfAssetPath 为键；星标 ui_designsystem__favorite_fill/
//     outline（星形 path：fill 实色 / 透明 fill + 1.25 stroke round-join），
//     tap → rsh/ith.o(chc,z) → pth.o → yb6(gaf, path, z) 写 favorites。
//   pth.t(chc) → qc0(gaf, chc.e, chc.a)：应用成功 → RecentPaperTemplate 上移 +
//     PaperTemplateUsage useCount+1。
//   sth{PRESET,GALLERY,MY_TEMPLATES}：recents/favorites 挂 PRESET tab
//     （qia{a,b}），ria 空态文案 no_recents/no_favorites；Harmony 统一分节
//     列表置顶两块（ADR-1338 登记的布局差异）。
// Harmony 落点：BundledTemplateMetaStore（preferences 持久化 JSON：
//   favorites/recents 有序 path 数组 + usage map）→ PaperTemplateGallery
//   顶部 Recents/Favorites 区块 + cell 星标 overlay + qgc.c 会话徽记
//   （NotePage.lastAppliedBundledTemplatePath）→ apply 成功后 recordUsed。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const store = readFileSync('note/src/main/ets/data/BundledTemplateMetaStore.ets', 'utf8');
const catalog = readFileSync('note/src/main/ets/core/model/PaperTemplateCatalog.ets', 'utf8');
const gallery = readFileSync('note/src/main/ets/ui/editor/PaperTemplateGallery.ets', 'utf8');
const page = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const en = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 元数据存储（gaf/qsh 等价）──
check(/class BundledTemplateMetaStore/.test(store), '元数据存储类');
check(/STORE_NAME: string = 'bundledPaperTemplateMeta'/.test(store), '专用 prefs store');
check(/FAVORITES_KEY[\s\S]{0,40}?'favoritePaperTemplates'/.test(store),
  'FavoritePaperTemplate 等价键');
check(/RECENTS_KEY[\s\S]{0,40}?'recentPaperTemplates'/.test(store),
  'RecentPaperTemplate 等价键');
check(/USAGE_KEY[\s\S]{0,40}?'paperTemplateUsage'/.test(store),
  'PaperTemplateUsage 等价键');
check(/BUNDLED_TEMPLATE_RECENTS_LIMIT: number = 36/.test(store),
  'nsh case110 36 条裁剪上限');
check(/paths\.unshift\(pdfAssetPath\)/.test(store), 'favoritedAt DESC 首插');
check(/recents\.unshift\(pdfAssetPath\)/.test(store) &&
  /recents\.length > BUNDLED_TEMPLATE_RECENTS_LIMIT/.test(store),
  'usedAt DESC 上移 + 36 裁剪');
check(/usage\[templateUuid\] = /.test(store) &&
  /\+ 1/.test(store), 'PaperTemplateUsage useCount+1');
check(/setFavorite\(pdfAssetPath: string, favorite: boolean\)/.test(store),
  'pth.o(chc,z) 等价签名');
check(/recordUsed\(pdfAssetPath: string, templateUuid: string\)/.test(store),
  'pth.t(chc) 等价签名（path+uuid 双键）');
check(!/RecentGalleryTemplate[^—-]*CREATE|RecentGalleryTemplate.*put/.test(store),
  'RecentGalleryTemplate 云端表 fail-closed 不落库');

// ── path→variant 精确反查（s7n.d/mapI0）──
check(/findBundledPaperVariantByPath/.test(catalog), 'pdfAssetPath 精确反查');
check(/variant\.rawfilePath === rawfilePath/.test(catalog) &&
  /template: template, variant: variant/.test(catalog), '按存入路径查 exact variant');

// ── 图库 UI（qia/ria/q9l.b/ibn.c）──
check(/@State private favoritePaths/.test(gallery) &&
  /@State private recentPaths/.test(gallery), '区块数据源 state');
check(/getFavoritePaths\(\)/.test(gallery) && /getRecentPaths\(\)/.test(gallery),
  'aboutToAppear 载入 favorites+recents');
check(/paper_templates_recents/.test(gallery) &&
  /paper_templates_favorites/.test(gallery), 'Recents/Favorites 区块标题');
check(/paper_templates_no_recents/.test(gallery) &&
  /paper_templates_no_favorites/.test(gallery), 'ria 空态文案');
check(/itemsFromPaths\(this\.recentPaths\)/.test(gallery) &&
  /itemsFromPaths\(this\.favoritePaths\)/.test(gallery),
  '区块按存储序渲染（favoritedAt/usedAt DESC）');
check(/findBundledPaperVariantByPath\(path\)/.test(gallery),
  '区块 cell = 存入的 exact variant');
check(/toggleFavorite/.test(gallery) && /setFavorite\(variant\.rawfilePath/.test(gallery),
  '星标 → pth.o 等价写');
check(/favoritePaths\.slice\(\)/.test(gallery), '乐观更新');
check(/getFavoritePaths\(\)\.then[\s\S]{0,120}?favoritePaths = paths/.test(gallery),
  '写库失败回滚显示态');
check(/FAVORITE_STAR_PATH/.test(gallery), 'favorite_fill/outline 星形 path');
check(/strokeWidth\(1\.25\)/.test(gallery) && /strokeLineJoin\(LineJoinStyle\.Round\)/.test(gallery),
  'outline 版 1.25 stroke round-join');
check(/resolveTokens\(\)\.accent\)/.test(gallery), 'fill 版 accent 填充');
check(/@Prop favorite/.test(gallery) && /@Prop current/.test(gallery),
  'cell qgc.d/qgc.c props');
check(/onToggleFavorite/.test(gallery) &&
  /命中测试落在最内层组件/.test(gallery),
  '星标 tap 不触发 cell 应用（最内层命中）');
check(/paper_templates_unfavorite|paper_templates_favorite/.test(gallery),
  '星标无障碍文案');
check(/appliedVariantPath/.test(gallery) &&
  /rawfilePath ===\s*this\.appliedVariantPath/.test(gallery), 'qgc.c 会话徽记');

// ── 宿主（NotePage）──
check(/lastAppliedBundledTemplatePath/.test(page), 'a1d Preset 会话徽记源');
check(/appliedVariantPath: this\.lastAppliedBundledTemplatePath/.test(page),
  '徽记透传图库');
check(/recordUsed\(variant\.rawfilePath, match\.template\.uuid\)/.test(page),
  '应用成功 → qc0 recents+usage（path+uuid）');
check(/findBundledPaperVariantByPath\(variant\.rawfilePath\)/.test(page),
  'uuid 反查（chc.a）');

// ── 字符串 ──
for (const key of ['paper_templates_recents', 'paper_templates_favorites',
  'paper_templates_no_recents', 'paper_templates_no_favorites',
  'paper_templates_favorite', 'paper_templates_unfavorite']) {
  check(en.includes(`"name": "${key}"`), `en:${key}`);
  check(zh.includes(`"name": "${key}"`), `zh:${key}`);
}
check(en.includes('"Designs you apply show up here."'), 'no_recents 原文');
check(en.includes('"Star a design to keep it here."'), 'no_favorites 原文');

console.log(`d02-original-paper-template-favorites OK — ${n} checks`);
