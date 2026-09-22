// Phase 622 — 空白处长按菜单项集 {PASTE, SELECT_ALL}（yqa.f）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   yqa.java:184-215 — 菜单项源 iterableM0：z3 → 剪贴板动态项
//     (rbb.m())；否则 a2gVar3==a2gVar → m18.m0(tqe.PASTE,
//     tqe.SELECT_ALL)；再否则 tqe.a()。过滤循环：ordinal2（PASTE）
//     需 zHasPrimaryClip（tr1.a.a().hasPrimaryClip()——剪贴板有内容
//     即产出，元素负载或系统图片任一）；ordinal6（REMOVE_HIGHLIGHT，
//     文本菜单项）需 z4 = eh5.b——SELECT_ALL 不在门控集内，本项集
//     中无条件产出（空页点击=空选，等价 no-op）。
//   tqe.java — 菜单项枚举含 PASTE/SELECT_ALL。
//   fvb 选择体系 — SELECT_ALL 产出覆盖全页的 ftc 多选（未分组
//     实体平铺 + 顶层组整体入选）。
// Harmony 对齐：ClipboardPasteContextMenu 产出两项——
//   PASTE：canPasteClipboardNow() || canUseOriginalClipboardImage()
//     门（元素剪贴板/系统图片任一→hasPrimaryClip 等价）；点击时
//     元素剪贴板优先 pasteClipboard(长按锚点)，否则系统图片粘贴。
//   SELECT_ALL：本项集中无门（原过滤只门控 PASTE 与
//     REMOVE_HIGHLIGHT）；selectAllPageElements() 经
//     resolveOriginalGroupSelection(全 id) 归并出顶层组+平铺实体
//     →selectElementIds → ftc 多选。
//   recentInteractionGateActive() 200ms 抑制保持包在最外层
//   （g39.b()，Phase 620）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const BASE_STR = 'note/src/main/resources/base/element/string.json';
const ZH_STR = 'note/src/main/resources/zh_CN/element/string.json';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 菜单结构：200ms 门包裹，PASTE→SELECT_ALL 顺序 ---
const mIdx = view.indexOf('private ClipboardPasteContextMenu()');
check(mIdx > 0, 'ClipboardPasteContextMenu present');
const m = view.slice(mIdx, mIdx + 2600);
check(m.includes('if (!this.recentInteractionGateActive())'),
  'g39.b() 200ms gate wraps all items (Phase 620 preserved)');
check(m.includes('this.canPasteClipboardNow() || this.canUseOriginalClipboardImage()'),
  'PASTE gated on element-clipboard OR system-image (hasPrimaryClip parity)');
check(m.indexOf("app.string.paste") < m.indexOf('app.string.select_all'),
  'PASTE precedes SELECT_ALL (m18.m0(PASTE, SELECT_ALL) order)');
check(m.includes("MenuItem({ content: $r('app.string.select_all') })"),
  'SELECT_ALL produced unconditionally in this item set — the ordinal6 ' +
  'filter gates REMOVE_HIGHLIGHT (text menu only), not SELECT_ALL');

// --- PASTE 点击：元素剪贴板优先于系统图片 ---
check(m.includes('this.canPasteClipboardNow() && target !== null'),
  'element clipboard preferred when both paste sources available');
check(m.includes('this.pasteClipboard(target)'),
  'element paste goes through pasteClipboard(long-press anchor)');
check(m.includes('this.startOriginalClipboardImagePaste()'),
  'system-image paste remains the fallback path');
check(m.includes('this.clipboardPasteTarget !== null ?'),
  'paste target = recorded long-press anchor (yqa a76 anchor parity)');

// --- SELECT_ALL 实现：全 id → resolveOriginalGroupSelection → 顶层组 ---
const saIdx = view.indexOf('private selectAllPageElements()');
check(saIdx > 0, 'selectAllPageElements present');
const sa = view.slice(saIdx, saIdx + 2400);
check(sa.includes('resolveOriginalGroupSelection(\n      allIds, allIds, this.selectionGroups)'),
  'all entity ids resolved through group selection (top-level groups only)');
check(sa.includes('this.selectionTool.selectElementIds('),
  'resolved ids fed into selectElementIds (ftc multi-selection)');
check(sa.includes('this.completedStrokes.filter') && sa.includes('this.shapes.filter') &&
  sa.includes('this.textBlocks.filter') && sa.includes('this.imageBlocks.filter') &&
  sa.includes('this.mathBlocks.filter'),
  'all five element kinds participate in select-all');
check(sa.includes('this.updateSelectionOverlay()') && sa.includes('this.renderFrame()'),
  'overlay + frame refreshed after select-all');

// --- SELECT_ALL 动作在无元素页为 no-op（等价原版的空选） ---
check(!view.includes('hasSelectablePageContent'),
  'no content gate remains — SELECT_ALL ungated like the original');
const sa2 = view.slice(saIdx, saIdx + 400);
check(sa2.includes('allIds.length === 0'),
  'empty-page select-all early-returns (original produces empty selection)');

// --- 字符串资源：select_all 双语 ---
const baseStr = read(BASE_STR);
const zhStr = read(ZH_STR);
check(baseStr.includes('"name": "select_all"') && baseStr.includes('"value": "Select All"'),
  'base string select_all = Select All');
check(zhStr.includes('"name": "select_all"') && zhStr.includes('"value": "全选"'),
  'zh_CN string select_all = 全选');

console.log(`D02_ORIGINAL_LONGPRESS_MENU_ITEMS_OK TOTAL=${n} FAILED=0`);
