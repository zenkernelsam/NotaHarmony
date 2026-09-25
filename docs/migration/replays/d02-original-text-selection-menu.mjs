// Phase 758 — 文本选区菜单定制项（tqe.a() 尾部三项）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   yqa.java:182-218 — f(uub,…)：非折叠选区 → tqe.a() 全量枚举；
//     ordinal2=PASTE 需 hasPrimaryClip、ordinal6=REMOVE_HIGHLIGHT
//     需 eh5.b；折叠 caret → [PASTE, SELECT_ALL]。
//   tqe.java — 枚举序 CUT(0)/COPY(1)/PASTE(2)/SELECT_ALL(3)/
//     LINK(4)/HIGHLIGHT(5)/REMOVE_HIGHLIGHT(6)。
//   q39.java:32-72 — ActionMode.Callback：项集写系统 ActionMode；
//     onActionItemClicked → r39 分发 + finish。
//   eh5/br2.g — eh5{iu1 色, boolean}：a=当前高亮色（默认 iu1.i 黄）、
//     b=REMOVE_HIGHLIGHT 门；cve:143/fm7:127 施加时写 eh5(color,true)。
// Harmony：TextArea.editMenuOptions（API12+）——onCreateMenu 在系统项
//   尾部按 tqe 序追加 LINK/HIGHLIGHT/REMOVE_HIGHLIGHT（相交门控）；
//   onMenuItemClick 分发复用 openLinkSheet/applyHighlightColor；
//   lastHighlightColor 对齐 eh5.a（默认黄=iu1.i 语义）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const OVERLAY = 'note/src/main/ets/ui/components/TextBlockOverlay.ets';
const STRINGS = 'note/src/main/resources/base/element/string.json';
const ZH = 'note/src/main/resources/zh_CN/element/string.json';
const EVIDENCE = 'docs/migration/evidence/phase-758-text-selection-menu.md';
const ADR = 'docs/migration/adr/ADR-0706-text-selection-menu.md';

const overlay = readFileSync(OVERLAY, 'utf8');
const strings = readFileSync(STRINGS, 'utf8');
const zh = readFileSync(ZH, 'utf8');
const evidence = readFileSync(EVIDENCE, 'utf8');
const adr = readFileSync(ADR, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- editMenuOptions 接线 ---
check(overlay.includes('.editMenuOptions({'),
  'editMenuOptions modifier on TextArea (q39 ActionMode parity)');
check(overlay.includes('onTextSelectionMenuCreate') &&
  overlay.includes('onTextSelectionMenuItem'),
  'onCreateMenu + onMenuItemClick both wired');

// --- 构建：系统项保留 + 尾部定制三项，tqe 序 ---
const create = overlay.slice(overlay.indexOf(
  'private onTextSelectionMenuCreate'), overlay.indexOf(
  'private onTextSelectionMenuItem'));
check(create.includes('menuItems.concat(custom)'),
  'custom items appended AFTER system items (tqe tail order)');
check(create.includes('s === e || this.photoImportLeaseActive') ||
  /s === e/.test(create),
  'collapsed caret → no custom items (original [PASTE, SELECT_ALL] only)');
const order = ['text_link', 'text_highlight', 'highlight_remove'];
let last = -1;
for (const key of order) {
  const idx = create.indexOf(`TextMenuItemId.of('${key}')`);
  check(idx > last, `custom item order ${key} (tqe ordinal 4/5/6)`);
  last = idx;
}
check(create.includes('rangeIntersectsHighlight(s, e)') &&
  create.indexOf('rangeIntersectsHighlight(s, e)') <
  create.indexOf("TextMenuItemId.of('highlight_remove')"),
  'REMOVE_HIGHLIGHT gated on highlight intersection (eh5.b parity)');
check(create.includes("$r('app.string.text_link')") &&
  create.includes("$r('app.string.text_highlight')") &&
  create.includes("$r('app.string.highlight_remove')"),
  'custom item labels use original string keys');

// --- 相交门（eh5.b 近似） ---
check(overlay.includes('private rangeIntersectsHighlight(s: number, e: number): boolean'),
  'rangeIntersectsHighlight helper (any overlapping highlighted run)');
check(overlay.includes('run.style.highlightColor !== undefined'),
  'intersection probe tests highlightColor presence');

// --- 分发：消费语义 + 三项行为 ---
const click = overlay.slice(overlay.indexOf(
  'private onTextSelectionMenuItem'));
check(/menuItem\.id\.equals\(TextMenuItemId\.of\('text_link'\)\)/.test(click),
  'LINK item dispatched by TextMenuItemId.equals');
check(click.indexOf('this.openLinkSheet()') >
  click.indexOf('this.caretSelectionStart = s'),
  'LINK → selection set to range → openLinkSheet (en5.c parity)');
check(click.includes('this.applyHighlightColor(this.lastHighlightColor, s, e)'),
  'HIGHLIGHT → applyHighlightColor(eh5.a current color)');
check(click.includes('this.applyHighlightColor(null, s, e)'),
  'REMOVE_HIGHLIGHT → applyHighlightColor(null) clears runs');
check((click.match(/return true;/g) ?? []).length >= 3 &&
  click.includes('return false;'),
  'custom ids consumed (r39 finish parity); system ids pass through');

// --- eh5.a 当前高亮色追踪 ---
check(overlay.includes('@State lastHighlightColor: number = 1716898048'),
  'lastHighlightColor state defaults to palette yellow (iu1.i parity)');
const toggle = overlay.slice(overlay.indexOf(
  'private toggleHighlightColor'), overlay.indexOf(
  'private toggleHighlightColor') + 700);
check(toggle.includes('this.lastHighlightColor = color'),
  'toggleHighlightColor funnel updates eh5.a (palette/recents/HSV)');

// --- 字符串键 ---
for (const s of ['text_link', 'text_highlight', 'highlight_remove']) {
  check(strings.includes(`"name": "${s}"`), `base string ${s}`);
  check(zh.includes(`"name": "${s}"`), `zh string ${s}`);
}

// --- 文档 ---
check(evidence.includes('yqa.f') && evidence.includes('tqe') &&
  evidence.includes('eh5'),
  'evidence cites yqa.f/tqe/eh5');
check(evidence.includes('editMenuOptions'),
  'evidence documents Harmony editMenuOptions path');
check(adr.includes('tqe') && adr.includes('eh5.b'),
  'ADR records tqe order + eh5.b gate');
check(adr.includes('rbb.m()') || adr.includes('剪贴板动态'),
  'ADR registers clipboard-dynamic-payload boundary');

console.log(`D02_ORIGINAL_TEXT_SELECTION_MENU_OK TOTAL=${n} FAILED=0`);
