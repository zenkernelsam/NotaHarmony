// Phase 592 — 文本块链接点按 → 锚定菜单 [Open, Copy Link]。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dl1.java — 各分支 ttc（文本块实体命中）→ uw2 case4。
//   uw2.java case4 — xtcVar2.d(new qke(ttcVar.a), …) 派发 TextBlock 事件；
//     yqaVar.g.m(new sqa(rej.i(zn9.f(j, uubVar.f), uubVar.e), 0)) 计算
//     点按偏移 → hqe 链接 span；yqaVar.b.b(new tqa(uubVar, 0)) 切换
//     CursorDisplayState。
//   rej.java:261 — rej.i(j, ti3)：点按 → 文本偏移 → hqe{offset,len}。
//   sqa.java — dgj.d(jtc, hqe)：把命中链接段锚进文本块态（fke(hqe,hqe)）。
//   g1f.java:240-246 — pca 链接点击事件 → xj2.A 弹出
//     m18.m0(wg7.OPEN, wg7.COPY_LINK)（Open/Copy Link 二项菜单）。
//   wg7.java — 链接菜单枚举 OPEN/COPY_LINK/EDIT/REMOVE（完整四项走
//     ww2:350 编辑表面；pca 只出前两项）。
//   vm5.java — OpenLinkClicked(url=…) 打开链接。
//   n94.java:240-250 — link_menu_open/copy_link/edit/remove 文案。
// Harmony：Canvas2DTextRenderer.linkAtPoint 复刻布局行遍历做偏移→链接
//   span 命中（含跨行段世界包围盒）；NoteCanvasView 在选区外按下与无选区
//   按下两条 ttc 路径前置链接探测；命中 → showActionMenu
//   [link_open, copy_link]（openLink / pasteboard 复制）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const RENDERER = 'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const STRINGS = 'note/src/main/resources/base/element/string.json';
const ZH = 'note/src/main/resources/zh_CN/element/string.json';

const renderer = readFileSync(RENDERER, 'utf8');
const canvas = readFileSync(CANVAS, 'utf8');
const strings = readFileSync(STRINGS, 'utf8');
const zh = readFileSync(ZH, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- linkAtPoint：点按 → 布局偏移 → 链接 span（rej.i/zn9.f 等价） ---
check(renderer.includes('export interface TextBlockLinkHit'),
  'TextBlockLinkHit result type');
check(renderer.includes('linkAtPoint(element: TextBlockElement, context: RenderContext'),
  'linkAtPoint public API');
const linkFn = renderer.slice(renderer.indexOf('linkAtPoint(element: TextBlockElement'),
  renderer.indexOf('linkAtPoint(element: TextBlockElement') + 5200);
check(linkFn.includes('this.inverseTransformPoint(worldPoint, element)'),
  'world → local inverse transform');
check(linkFn.includes('this.layoutLines(ctx, characters, characterStyles, element)'),
  'reuses the render layout line split');
check(linkFn.includes('(element.fontSize + 8) * spacing'),
  'line band follows the render line advance');
check(linkFn.includes('paragraphIndent(element, paragraph)') &&
  linkFn.includes('paragraph.alignment === 2') && linkFn.includes('paragraph.alignment === 3'),
  'x-walk replicates indent + center/right alignment');
check(linkFn.includes('this.characterIndexAt('),
  'per-character offset lookup under the tap');
check(linkFn.includes('characterStyles[linkIndex]?.link !== undefined'),
  'hit requires a link span at the offset');

// --- buildLinkHit：连续同 url span 扩展 + 跨行世界包围盒 ---
const buildFn = renderer.slice(renderer.indexOf('private buildLinkHit('),
  renderer.indexOf('private buildLinkHit(') + 4200);
check(buildFn.includes('characterStyles[start - 1]?.link === url') &&
  buildFn.includes('characterStyles[end]?.link === url'),
  'contiguous same-url span expansion');
check(buildFn.includes('matrix[0] * px + matrix[1] * py + matrix[2]'),
  'local → world affine for the anchor rect');
check(buildFn.includes('overlapStart') && buildFn.includes('overlapEnd'),
  'per-line overlap measure for multi-line links');

// --- 画布：ttc 路径前置链接探测 ---
const selBranch = canvas.slice(canvas.indexOf('isSelectionActive()'),
  canvas.indexOf('isSelectionActive()') + 9000);
check(selBranch.includes('this.linkHitOnTextBlock(hitId, canvasP)') &&
  selBranch.includes('this.showTextBlockLinkMenu(linkHit)'),
  'outside-press on text block probes links before TapToSelect');
check(selBranch.indexOf('this.linkHitOnTextBlock(hitId, canvasP)') <
  selBranch.indexOf('this.applyTapSelect(hitId)'),
  'link probe precedes the TapToSelect dispatch');
check(selBranch.includes('this.textBlockLinkAt(canvasP)'),
  'no-selection press probes text-block links before the lasso');

// --- 菜单：g1f pca [OPEN, COPY_LINK] ---
const menu = canvas.slice(canvas.indexOf('showTextBlockLinkMenu(hit: TextBlockLinkHit)'),
  canvas.indexOf('showTextBlockLinkMenu(hit: TextBlockLinkHit)') + 2400);
check(menu.includes('promptAction.showActionMenu') &&
  menu.includes("$r('app.string.link_open')") &&
  menu.includes("$r('app.string.copy_link')"),
  'two-item menu [Open, Copy Link] (wg7.OPEN/COPY_LINK)');
check(menu.includes('context.openLink(hit.url)'),
  'Open → openLink (OpenLinkClicked parity)');
check(menu.includes('pasteboard.createPlainTextData(hit.url)') &&
  menu.includes('pasteboard.getSystemPasteboard().setData(data)'),
  'Copy Link → system pasteboard');
check(menu.includes("$r('app.string.link_open_failed')"),
  'open failure toast (error_unable_to_open_link parity)');
check(menu.includes("$r('app.string.link_copied')"),
  'copy success toast');

// --- 字符串资源 ---
for (const s of ['link_open', 'copy_link', 'link_open_failed', 'link_copied']) {
  check(strings.includes(`"name": "${s}"`), `base string ${s}`);
  check(zh.includes(`"name": "${s}"`), `zh string ${s}`);
}
check(strings.includes('"value": "Open"') && strings.includes('"value": "Copy Link"'),
  'labels match original link_menu_open/copy_link copy');

// --- 既有链接数据链完整（解码→样式 run→下划线渲染） ---
check(renderer.includes('style.link !== undefined'),
  'link style run still drives underline render');

console.log(`D02_ORIGINAL_TEXTBLOCK_LINK_TAP_OK TOTAL=${n} FAILED=0`);
