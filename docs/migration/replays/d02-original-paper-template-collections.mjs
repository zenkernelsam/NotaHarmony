// Phase 1404 — 原版 1.4.2 捆绑模板集合区块细节 + See all 钻入 +
// Current 徽记（dt/m56/u7n.d/zia/s1a/d2n 等价）。
// 原版证据（decompiled_1.4.2）：
//   ria{FAVORITES(title,no_favorites), RECENTS(title,no_recents),
//     CUSTOM(title,no_custom)}：F=区块标题 res，G=空态文案 res。
//   dt case8：aq8 分页器遍历 ria.K 时 `ria!=H || !qia.b.isEmpty()` ——
//     RECENTS 区块/页在列表为空时整块隐藏；FAVORITES 恒在。
//   m56：每集合页 = bbn.b(ria.F 标题, trailing s1a case2 "See all"
//     （listG 非空才渲染，o9n 文本钮）, content zia)。
//   zia：awa==null && listG 空 → u7n.c(ria.G) 空态；否则逐项 u7n.b。
//   "See all" → oe(bz5,ria) → buh.b=ria → x2n 切到 u7n.d 独立集合页。
//   u7n.d(ria)：标题+See all+网格；zIsEmpty → c(ria.G)。
//   d2n.g + p9n.a：qgc.c 命中 → 左下 eta(a.b.a→a.c.a) 渐变徽记 +
//     ui_templates__current 文本；h2n.a = 收藏心形动画（仅动效）。
//   ia6/xcm.b search_gallery 属于云端 GALLERY tab —— fail-closed。
// Harmony 落点：PaperTemplateGallery sections() RECENTS 空隐藏 +
//   collection 标记 See all → expandedSection 钻入（chevron_left 返回 +
//   集合标题）；cell current → BottomStart accent 圆角 "Current" 徽记
//   （替代 Phase 1402 的 accent 描边近似）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const gallery = readFileSync('note/src/main/ets/ui/editor/PaperTemplateGallery.ets', 'utf8');
const en = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── dt case8：RECENTS 空隐藏 ──
check(/if \(recentItems\.length > 0\)/.test(gallery) &&
  /sectionKey: 'recents'/.test(gallery), 'RECENTS 区块空时隐藏');
check(/paper_templates_recents/.test(gallery), 'recents 标题串');
// FAVORITES 恒在 + 空态
check(/sectionKey: 'favorites', collection: true/.test(gallery) &&
  /paper_templates_no_favorites/.test(gallery), 'FAVORITES 恒在 + 空态文案');
check(/collection\?: boolean/.test(gallery), '区块 collection 标记');

// ── s1a case2：See all（非空集合尾随）──
check(/paper_templates_see_all/.test(gallery) &&
  /section\.collection === true && section\.items\.length > 0/.test(gallery),
  'See all 仅集合非空区块尾随');
check(/this\.expandedSection = section\.sectionKey/.test(gallery),
  'See all → 钻入（buh.b=ria 等价）');
check(/@State private expandedSection: string = ''/.test(gallery),
  'expandedSection 状态');
check(/expandedItems\(\): GalleryCellItem\[\]/.test(gallery), '钻入页取集合 items');
check(/expandedSection !== ''/.test(gallery) &&
  /chevron_left/.test(gallery) && /app\.string\.back/.test(gallery),
  '钻入页返回钮（x2n.h 返回等价）');
check(/expandedEmptyRes\(\): Resource/.test(gallery) &&
  /paper_templates_no_recents/.test(gallery) &&
  /paper_templates_no_favorites/.test(gallery),
  '钻入页 ria.G 空态文案');
check(/this\.cellGrid\(this\.expandedItems\(\)\)/.test(gallery), '钻入页整页网格');

// ── d2n.g/p9n.a：Current 徽记 ──
check(/paper_templates_current/.test(gallery) &&
  /Alignment\.BottomStart/.test(gallery), 'Current 左下徽记');
check(!/border\(this\.current/.test(gallery), '去掉 accent 描边近似（原版为徽记）');
check(/current: boolean/.test(gallery), 'cell current prop 保留');

// ── 字符串 ──
check(en.includes('"paper_templates_see_all"') && en.includes('"See all"') &&
  en.includes('"paper_templates_current"') && en.includes('"Current"'),
  'en See all/Current');
check(zh.includes('"paper_templates_see_all"') && zh.includes('"查看全部"') &&
  zh.includes('"paper_templates_current"') && zh.includes('"当前"'),
  'zh 查看全部/当前');

console.log(`d02-original-paper-template-collections OK — ${n} checks`);
