// Phase 670 — 原版分享面板任意页子集选择（v6d.l 页集合 +
// b7d.q(i,z) 页 toggle + r6d.PAGE_SELECTION 缩略图栅格屏）。
// 原版证据（decompiled_1.0.3）：
//   b7d.java   分享 ViewModel——Q=v6d 状态机；l=Set<Integer> 页集合
//     （null=全部页）、m=页总数、n=r6d 屏态；q(i,z) 基集
//     null→rh8.V(0,m) 全量物化后 add/remove；l(i,i2) 缩略图窗口
//     预取进 X→o；j()/k() 回 MAIN；partial = set!=null&&size!=m。
//   r6d.java   MAIN / PAGE_SELECTION / PASSWORD_ENTRY 三屏枚举。
//   strings.xml ui_share__page_range="Page range"、_all="All"、
//     _selection="%1$d of %2$d"。
// Harmony 对齐：EditorToolbar 分享面板 shareScreen('main'|'pages')
// + sharePageIndexes:number[]|null（null=All）+ 页范围行（Page
//   range / All / "X of Y"）→ 4 列 SharePageCell 栅格（缩略图 +
//   勾选圈 + tap toggle + select/deselect-all + Done 回 MAIN）；
//   onSharePdf/onShareImage 签名 allPages→pageIndexes；NOTE 恒整册；
//   sheet onDisappear 重置屏态与集合（b7d.j()/f() 语义）；
//   NotePage resolveSharePages 按页序过滤 + 懒建串行缩略图链。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const b7d = fs.readFileSync(`${originalRoot}sources/defpackage/b7d.java`, 'utf8');
const r6d = fs.readFileSync(`${originalRoot}sources/defpackage/r6d.java`, 'utf8');
const v6d = fs.readFileSync(`${originalRoot}sources/defpackage/v6d.java`, 'utf8');
const origStrings = fs.readFileSync(
  `${originalRoot}resources/res/values/strings.xml`, 'utf8');

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// ---------- 原版证据 ----------
check(v6d.includes('public final Set l;') &&
  v6d.includes('public final int m;'),
  'v6d carries the page set (l) + page count (m)');
check(r6d.includes('"MAIN"') && r6d.includes('"PAGE_SELECTION"') &&
  r6d.includes('"PASSWORD_ENTRY"'),
  'r6d is the MAIN/PAGE_SELECTION/PASSWORD_ENTRY screen enum');
check(b7d.includes('setW1 = au1.W1(set != null ? set : rh8.V(0, v6dVar.m))') &&
  b7d.includes('setW1.add(numValueOf)') && b7d.includes('setW1.remove(numValueOf)'),
  'b7d.q materializes all-pages when null then adds/removes the index');
check(b7d.includes('set != null && set.size() != v6dVar2.m'),
  'partial flag = set non-null and smaller than the page count');
check(origStrings.includes('ui_share__page_range') &&
  origStrings.includes('>Page range<') &&
  origStrings.includes('ui_share__page_range_all') &&
  origStrings.includes('ui_share__page_range_selection') &&
  origStrings.includes('%1$d of %2$d'),
  'original strings: Page range / All / "X of Y"');

// ---------- Harmony：状态与屏机 ----------
check(toolbar.includes('@State sharePageIndexes: number[] | null = null'),
  'toolbar holds the nullable page-index set (v6d.l)');
check(toolbar.includes("@State shareScreen: string = 'main'"),
  'toolbar holds the sheet screen state (r6d)');
check(toolbar.includes("this.shareScreen === 'pages'") &&
  toolbar.includes('buildSharePagePicker') &&
  toolbar.includes('buildShareMain'),
  'sheet switches between main and page-selection screens');
check(toolbar.includes("this.shareScreen = 'pages';") &&
  toolbar.includes("this.shareScreen = 'main';"),
  'screen transitions both ways wired');
check(toolbar.includes('onDisappear') &&
  toolbar.includes('this.sharePageIndexes = null;'),
  'sheet dismiss resets screen + selection (b7d.j/f semantics)');

// ---------- Harmony：页范围行与 toggle ----------
check(toolbar.includes("share_page_range") &&
  toolbar.includes('this.shareSelectionLabel()'),
  'page-range row label + dynamic value');
check(toolbar.includes('selected.length === this.sharePages.length') &&
  toolbar.includes('share_range_selected'),
  'full-covering subset normalizes to the All label');
check(toolbar.includes('base.indexOf(pageIndex)') &&
  toolbar.includes('base.splice(at, 1)') &&
  toolbar.includes('base.push(pageIndex)'),
  'toggleSharePage adds/removes indexes from the materialized set');
check(toolbar.includes('pages_deselect_all') &&
  toolbar.includes('pages_select_all') &&
  toolbar.includes('pages_done'),
  'picker header has select/deselect-all + Done');

// ---------- Harmony：栅格与 cell ----------
check(toolbar.includes('struct SharePageCell') &&
  toolbar.includes('@Prop checked: boolean = true') &&
  toolbar.includes('onToggle: (pageIndex: number) => void'),
  'SharePageCell renders checkable thumbnail cells');
check(toolbar.includes("columnsTemplate('1fr 1fr 1fr 1fr')"),
  'picker uses the 4-column thumbnail grid');
check(toolbar.includes('onRequest: this.onShareThumb'),
  'cells request thumbnails through the injected provider');

// ---------- Harmony：分发与消费 ----------
check(toolbar.includes('onSharePdf: (pageIndexes: number[] | null, password: string | null) => void') &&
  toolbar.includes('this.onSharePdf(this.sharePageIndexes, this.sharePassword);') &&
  toolbar.includes('this.onShareImage(format, this.sharePageIndexes);'),
  'format rows dispatch the nullable page set');
check(toolbar.includes('this.onShareNote();') &&
  !toolbar.includes('onShareNote(this.sharePageIndexes)'),
  'NOTE ignores the page set (whole-archive export)');
check(notePage.includes('resolveSharePages(pageIndexes: number[] | null)') &&
  notePage.includes('wanted.has(index)'),
  'NotePage filters pages by the index set in page order');
check(notePage.includes('sharePagesAsImages(format: string, pageIndexes: number[] | null)') &&
  notePage.includes('shareNoteAsPdf(pageIndexes: number[] | null, password: string | null)'),
  'export methods consume the nullable set');
check(notePage.includes('requestShareThumbnail') &&
  notePage.includes('shareThumbRenderer') &&
  notePage.includes('shareThumbChain'),
  'lazy serial thumbnail chain feeds the picker');
check(notePage.includes('sharePages: this.pages') &&
  notePage.includes('onShareThumb: (page: PageInfo): Promise<PixelMap | null>'),
  'toolbar picker props wired from NotePage');

// ---------- 字符串 ----------
check(baseStrings.includes('"share_page_range"') &&
  baseStrings.includes('"share_range_selected"') &&
  baseStrings.includes('"%d of %d"') &&
  zhStrings.includes('"share_page_range"') &&
  zhStrings.includes('"share_range_selected"'),
  'page-range strings localized in both locales');
check(!toolbar.includes('shareAllPages'),
  'superseded binary shareAllPages flag removed');

console.log(`D05_ORIGINAL_SHARE_PAGE_SUBSET_OK TOTAL=${total} FAILED=0`);
