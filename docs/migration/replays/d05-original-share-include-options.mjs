// Phase 672 — 原版分享面板分格式选项区 + include_* 开关 +
// "Share X" 动作行（v6d.c/i/j + dih.h/d/a/b + g6d）。
// 原版证据（decompiled_1.0.3）：
//   v6d.java   boolean i=includeBackground、j=includeRecording
//     （toString 标签确认）；构造器初值 i=false、j=true。
//   b7d.java   构造器：list.size()>1 → 默认 PDF 否则 LINK；
//     i() 导出协程 → pj(format, j=recordings, i=background, partial)。
//   s6d.java   LINK/PDF/NOTE/JPG/PNG 枚举序 + chip/action 双标签组。
//   dih.java   按 v6d.c ordinal 分派选项区：0=LINK→b（权限开关，
//     账号域）、1=PDF→h（页范围行+include_background+include_
//     recording+密码行）、2=NOTE→d（仅 include_recording）、
//     3/4=JPG/PNG→a（页范围行+include_background）。
//   fw2.java   include_background（templates 图标）/
//     include_recording（record_mic 图标）标签行。
//   j6d.java   e9e.a 开关分别绑 v6d.i（bg）与 v6d.j（rec）。
//   g6d.java   底部 Cancel + "Share X" 按钮（enabled=就绪且非忙，
//     忙时 b0b.a 转圈）。
//   strings.xml ui_share__include_background="Include background"、
//     _recording、chip_*/action_*、"Cancel"。
// Harmony 对齐：EditorToolbar shareFormat（v6d.c）chip 单选行 +
// 分格式选项区（pdf=范围+背景+录音+密码；note=录音；jpg/png=
// 范围+背景；link=不可用说明+Share 禁用）+ Cancel/"Share X"
// 动作行；shareIncludeBackground=false / shareIncludeRecording=
// true 初值与 b7d 构造器逐位对齐；onSharePdf/onShareImage 增
// includeBackground、onShareNote 增 includeRecording；
// ThumbnailRenderer.renderPageExport 增 exportBackground
// （'paper'|'white'|'transparent'——JPEG/PDF 无 alpha 填白、PNG
// 留透明）；NoteExporter.exportNote 增 includeRecordings（false
// 时录音资产+recordings.json 一并跳过）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const b7d = fs.readFileSync(`${originalRoot}sources/defpackage/b7d.java`, 'utf8');
const v6d = fs.readFileSync(`${originalRoot}sources/defpackage/v6d.java`, 'utf8');
const s6d = fs.readFileSync(`${originalRoot}sources/defpackage/s6d.java`, 'utf8');
const dih = fs.readFileSync(`${originalRoot}sources/defpackage/dih.java`, 'utf8');
const fw2 = fs.readFileSync(`${originalRoot}sources/defpackage/fw2.java`, 'utf8');
const j6d = fs.readFileSync(`${originalRoot}sources/defpackage/j6d.java`, 'utf8');
const g6d = fs.readFileSync(`${originalRoot}sources/defpackage/g6d.java`, 'utf8');
const pj = fs.readFileSync(`${originalRoot}sources/defpackage/pj.java`, 'utf8');
const origStrings = fs.readFileSync(
  `${originalRoot}resources/res/values/strings.xml`, 'utf8');

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const renderer = fs.readFileSync('note/src/main/ets/rendering/ThumbnailRenderer.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const exporter = fs.readFileSync('note/src/main/ets/data/NoteExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// ---------- 原版证据 ----------
check(v6d.includes('public final boolean i;') &&
  v6d.includes('public final boolean j;') &&
  v6d.includes('includeBackground') && v6d.includes('includeRecording'),
  'v6d.i=includeBackground / v6d.j=includeRecording confirmed');
check(b7d.includes('list.size() > 1 ? s6d.PDF : s6d.LINK'),
  'default format: PDF for multi-note, LINK for single');
check(b7d.includes('false, true, false, true, null, null, 0, r6d.I'),
  'initial state pins includeBackground=false includeRecording=true');
check(s6d.includes('LINK') && s6d.includes('PDF') &&
  s6d.includes('NOTE') && s6d.includes('JPG') && s6d.includes('PNG'),
  's6d declares the five format enum members');
check(dih.includes('dih.h(v6dVar2') && dih.includes('dih.d(v6dVar2') &&
  dih.includes('dih.a(v6dVar2') && dih.includes('dih.b(v6dVar2'),
  'dih dispatches per-format option sections h/d/a/b');
check(fw2.includes('ui_share__include_background') &&
  fw2.includes('ui_share__include_recording'),
  'fw2 renders both include_* labels');
check(j6d.includes('e9e.a(v6dVar.i') && j6d.includes('e9e.a(v6dVar.j'),
  'j6d binds switches to v6d.i and v6d.j');
check(g6d.includes('ui_share__cancel'),
  'g6d renders the Cancel action');
check(pj.includes('"Includes Recordings"') &&
  pj.includes('"Includes Background"') &&
  pj.includes('"Includes Page Range"'),
  'pj analytics carries both include flags + partial-range flag');
check(origStrings.includes('ui_share__include_background">Include background') &&
  origStrings.includes('ui_share__include_recording">Include recording') &&
  origStrings.includes('ui_share__action_pdf">Share PDF') &&
  origStrings.includes('ui_share__cancel">Cancel'),
  'original strings: include_* + Share X + Cancel');

// ---------- Harmony：状态与 chip 行 ----------
check(toolbar.includes("@State shareFormat: string = 'pdf'") &&
  toolbar.includes('@State shareIncludeBackground: boolean = false') &&
  toolbar.includes('@State shareIncludeRecording: boolean = true'),
  'v6d.c/i/j state with original defaults (bg=false, rec=true)');
check(toolbar.includes('ShareFormatChip($r(\'app.string.share_link\'), \'link\', false)') &&
  toolbar.includes('ShareFormatChip($r(\'app.string.share_pdf\'), \'pdf\', true)') &&
  toolbar.includes('ShareFormatChip($r(\'app.string.share_note\'), \'note\', true)') &&
  toolbar.includes('ShareFormatChip($r(\'app.string.share_jpg\'), \'jpg\', true)') &&
  toolbar.includes('ShareFormatChip($r(\'app.string.share_png\'), \'png\', true)'),
  'five format chips; LINK dimmed-unselectable (fail-closed)');
check(toolbar.includes('this.shareFormat = format;') &&
  toolbar.includes('this.shareFormat === format'),
  'chip tap selects the format (v6d.c)');

// ---------- Harmony：分格式选项区（dih.h/d/a 等价） ----------
check(/this\.shareFormat === 'pdf'\) \{[\s\S]*?ShareRangeRow\(\)[\s\S]*?share_include_background[\s\S]*?share_include_recording[\s\S]*?SharePasswordRow\(\)/.test(toolbar),
  'pdf section = range + background + recording + password (dih.h)');
check(/this\.shareFormat === 'note'\) \{\s*this\.ShareToggleRow\(\$r\('app\.string\.share_include_recording'\),\s*this\.shareIncludeRecording, 'rec'\)\s*\} else if/.test(toolbar),
  'note section = recording toggle only (dih.d)');
check(/'jpg' \|\| this\.shareFormat === 'png'\) \{[\s\S]*?ShareRangeRow\(\)[\s\S]*?share_include_background/.test(toolbar),
  'jpg/png section = range + background (dih.a)');
check(toolbar.includes('share_link_unavailable'),
  'link section explains the fail-closed state (dih.b is account-bound)');
check(toolbar.includes('Toggle({ type: ToggleType.Switch, isOn: value })') &&
  toolbar.includes("which === 'bg'") &&
  toolbar.includes('this.shareIncludeBackground = enabled;') &&
  toolbar.includes('this.shareIncludeRecording = enabled;'),
  'toggle rows bind the two include flags (j6d/e9e.a equivalent)');

// ---------- Harmony：动作行与分发 ----------
check(toolbar.includes("app.string.share_cancel") &&
  toolbar.includes('this.shareActionLabel()') &&
  toolbar.includes('this.dispatchShare()'),
  'Cancel + "Share X" action row (g6d equivalent)');
check(toolbar.includes('share_action_pdf') && toolbar.includes('share_action_note') &&
  toolbar.includes('share_action_jpg') && toolbar.includes('share_action_png') &&
  toolbar.includes('share_action_link'),
  'per-format Share action labels (s6d.L)');
check(toolbar.includes("if (this.shareFormat === 'link')") &&
  toolbar.includes('this.onShareNote(this.shareIncludeRecording)') &&
  toolbar.includes('this.onSharePdf(this.sharePageIndexes, this.sharePassword,\n        this.shareIncludeBackground)') &&
  toolbar.includes('this.onShareImage(this.shareFormat, this.sharePageIndexes,\n        this.shareIncludeBackground)'),
  'dispatchShare routes format + page set + password + include flags');
check(/onDisappear[\s\S]*?shareFormat = 'pdf'[\s\S]*?shareIncludeBackground = false[\s\S]*?shareIncludeRecording = true/.test(toolbar),
  'sheet dismiss resets format + include flags (v6d rebuild)');
check(!toolbar.includes('ShareFormatRow('),
  'superseded tap-to-export format rows removed');

// ---------- Harmony：导出管线消费 ----------
check(toolbar.includes('includeBackground: boolean) => void') &&
  notePage.includes('sharePagesAsImages(format: string, pageIndexes: number[] | null,\n    includeBackground: boolean)') &&
  notePage.includes('includeBackground ? \'paper\' :\n      (shareFormat === \'png\' ? \'transparent\' : \'white\')'),
  'image export maps includeBackground to paper/transparent|white');
check(notePage.includes('shareNoteAsPdf(pageIndexes: number[] | null, password: string | null,\n    includeBackground: boolean)') &&
  notePage.includes("includeBackground ? 'paper' : 'white'"),
  'pdf export maps includeBackground to paper/white');
check(notePage.includes('shareNoteAsFile(includeRecording: boolean)') &&
  notePage.includes('includeRecording).then'),
  'note export threads includeRecording into exportToFile');
check(renderer.includes("exportBackground: string = 'paper'") &&
  renderer.includes("exportBackground === 'paper'") &&
  renderer.includes("exportBackground === 'white'") &&
  renderer.includes("ctx.fillStyle = '#FFFFFF'") &&
  renderer.includes('ctx.fillRect(0, 0, pageSize.width, pageSize.height)'),
  'renderer honors paper/white/transparent background modes');
check(renderer.includes('renderPaper ? effectivePageBackground(page) : null'),
  'paper/PDF background loading skipped when includeBackground is off');
check(exporter.includes('includeRecordings: boolean = true') &&
  exporter.includes('includeRecordings ?\n        await new OriginalRecordingStore(this.db).listVisible(noteId) : []'),
  'NoteExporter skips recording assets + manifest when flag is off');

// ---------- 字符串 ----------
check(baseStrings.includes('"share_include_background"') &&
  baseStrings.includes('"share_include_recording"') &&
  baseStrings.includes('"share_action_pdf"') &&
  baseStrings.includes('"share_cancel"') &&
  baseStrings.includes('"share_link_unavailable"') &&
  zhStrings.includes('"share_include_background"') &&
  zhStrings.includes('"share_include_recording"') &&
  zhStrings.includes('"share_cancel"'),
  'include/action/cancel strings localized in both locales');

console.log(`D05_ORIGINAL_SHARE_INCLUDE_OPTIONS_OK TOTAL=${total} FAILED=0`);
