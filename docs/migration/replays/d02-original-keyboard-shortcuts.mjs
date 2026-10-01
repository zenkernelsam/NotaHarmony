// Phase 1407 — 原版硬件键盘快捷键（qa8/vla/bd8/f2 等价，1.4.2 证据）。
// 与 phase-1255 文本编辑 keymap（hke/k09/syh）不同：此面覆盖
// MainActivity.dispatchKeyEvent → vla.a 应用级查表（bma.a →
// lra.handleNavigationShortcut / if2）与 kom→ofk.L 画布级
// onKeyEvent（f2 case5 → bd8.B + 兜底链）两条通路。
//
// 原版证据（decompiled_1.4.2）：
//   qa8 = KeyChord{keyCode, ctrl, alt, shift} 四维精确匹配；
//   双参构造 qa8(i,mask)：ctrl=(mask&2)==0，alt=(mask&4)==0，
//   shift=(mask&8)==0——mask 位反向表"修饰键关闭"。
//   vla.a = {qa8(42,12)→xla new_note, qa8(55,12)→zla open_settings,
//     qa8(40,12)→wla back_to_library, qa8(76,12)→yla open_help}；
//   vla.b = qa8(42,4) = Ctrl+Shift+N new_window；
//   cma.a 末尾 qa8(111,14) = 纯 ESC dismiss_deselect。
//   MainActivity.dispatchKeyEvent：vla.a(keyEvent) 判 new-window 和弦
//   （无启动器也消费），vla.b 查表命中 → ACTION_UP 时 bma.a.f(ama)，
//   未命中 → super.dispatchKeyEvent 透传。
//   bd8.B（canvas onKeyEvent，KeyUp 分发 lxm.a(o,1)）：
//     Ctrl+={70}/+{81}/num+{157} → F(1.2f) 视口中心放大；
//     Ctrl+-{69}/num-{156} → F(0.8333333f)；
//     Ctrl+0{7}/num0{144} → ad8 → mfc.D(1.0/current, center) 回 100%；
//     Ctrl+Shift+E{33} → ea1.p(rc8 ShowShare)；
//     Ctrl+Shift+P{44} → ea1.p(oc8 OpenContentManager)；
//     Ctrl+R{46} → sc8 ToggleRecording（T.g.F 可用性门）；
//     Ctrl+F{34} → V.a.f(egj)+pc8 OpenSearch；
//     Ctrl+Home{122}/End{123} → jp8 scrollToTop/Bottom。
//   f2 兜底链（!(Q.m instanceof rsi) 门——文本编辑中不触发）：
//     Ctrl+Z→E() undo；Ctrl+Shift+Z/Ctrl+Y→C() redo；
//     Ctrl+C{31}|COPY{278}→copy；Ctrl+X{52}|CUT{277}→cut；
//     Ctrl+V{50}|PASTE{279}|Ctrl+Alt+V(qc8)→paste；
//     Ctrl+1..9{i0}→cxi(index) 第 N 个可见工具；
//     k0=308..311 厂商键+D() 前工具——G()=k24.a() 硬件门 fail-closed。
// Harmony 落点：OriginalKeyboardChords.ets（qa8/chord 表）+
//   LibraryPage.onKeyEvent（应用级）+ NoteCanvasView.onKeyEvent
//   （画布级，ofk.L 等价）+ NotePage.onKeyEvent（应用级兜底）+
//   PageOverviewPanel.searchSignal / EditorToolbar.shareSignal。

import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const chords = readFileSync('note/src/main/ets/data/OriginalKeyboardChords.ets', 'utf8');
const library = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const canvas = readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const notePage = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const panel = readFileSync('note/src/main/ets/ui/editor/PageOverviewPanel.ets', 'utf8');
const toolbar = readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── OriginalKeyboardChords.ets：qa8 模型 + 和弦表 ──
check(chords.includes('export interface OriginalKeyChord'), 'qa8 KeyChord 接口');
check(chords.includes('keyCode: number') && chords.includes('ctrl: boolean') &&
  chords.includes('alt: boolean') && chords.includes('shift: boolean'),
  'KeyChord 四维字段');
check(/export function matchKeyChord[\s\S]*?event\.keyCode === chord\.keyCode[\s\S]*?keyChordCtrl\(event\) === chord\.ctrl[\s\S]*?keyChordAlt\(event\) === chord\.alt[\s\S]*?keyChordShift\(event\) === chord\.shift/.test(chords),
  'matchKeyChord 四维精确匹配（qa8.equals）');

// 应用级和弦常量 + Harmony 键码（A-Z=2017-2042, 0-9=2000-2009）
check(chords.includes('ORIGIN_CHORD_NEW_NOTE') && chords.includes('keyCode: 2030'),
  'Ctrl+N new_note（KEYCODE_N=2030）');
check(/ORIGIN_CHORD_NEW_WINDOW[\s\S]*?shift: true/.test(chords), 'Ctrl+Shift+N new_window');
check(/ORIGIN_CHORD_OPEN_SETTINGS[\s\S]*?keyCode: 2043/.test(chords), 'Ctrl+, settings（COMMA=2043）');
check(/ORIGIN_CHORD_BACK_TO_LIBRARY[\s\S]*?keyCode: 2028/.test(chords), 'Ctrl+L back_to_library（L=2028）');
check(/ORIGIN_CHORD_OPEN_HELP[\s\S]*?keyCode: 2064/.test(chords), 'Ctrl+/ help（SLASH=2064）');
check(/ORIGIN_CHORD_DISMISS[\s\S]*?keyCode: 2070[\s\S]*?ctrl: false/.test(chords), '纯 ESC dismiss');

// 画布级键码集（缩放/滚动/动作）
check(/ORIGIN_ZOOM_IN_KEYCODES[^=]*=\s*\[2058, 2066, 2116\]/.test(chords),
  '缩放+键集 ={2058,+,num+2116}');
check(/ORIGIN_ZOOM_OUT_KEYCODES[^=]*=\s*\[2057, 2115\]/.test(chords),
  '缩放-键集 -{2057}/num-{2115}');
check(/ORIGIN_ZOOM_RESET_KEYCODES[^=]*=\s*\[2000, 2103\]/.test(chords),
  '重置键集 0{2000}/num0{2103}');
check(chords.includes('ORIGIN_KEYCODE_MOVE_HOME: number = 2081') &&
  chords.includes('ORIGIN_KEYCODE_MOVE_END: number = 2082'), 'Home/End 键码');
check(chords.includes('ORIGIN_KEYCODE_F: number = 2022') &&
  chords.includes('ORIGIN_KEYCODE_E: number = 2021') &&
  chords.includes('ORIGIN_KEYCODE_P: number = 2032') &&
  chords.includes('ORIGIN_KEYCODE_R: number = 2034'), 'F/E/P/R 键码');
check(chords.includes('ORIGIN_KEYCODE_COPY: number = 2620') &&
  chords.includes('ORIGIN_KEYCODE_PASTE: number = 2622') &&
  chords.includes('ORIGIN_KEYCODE_CUT: number = 2624'), '专用 COPY/PASTE/CUT 键码');
check(/ORIGIN_TOOL_SELECT_DIGIT_BASE: number = 2001/.test(chords) &&
  /ORIGIN_TOOL_SELECT_DIGIT_END: number = 2009/.test(chords), '数字键段 1..9');
check(/toolSelectDigitIndex[\s\S]*?keyChordCtrl\(event\)[\s\S]*?keyChordShift\(event\)/.test(chords),
  '数字工具门 = ctrl && !shift（i0 语义）');
check(chords.includes('308..311') || chords.includes('308'), '厂商键 k0 fail-closed 登记');

// ── LibraryPage：应用级查表 ──
check(library.includes('onLibraryKeyEvent'), 'Library 键盘处理器');
check(/\.onKeyEvent\(\(event: KeyEvent\): boolean => \{\s*return this\.onLibraryKeyEvent\(event\);/.test(library),
  '根组件挂 onKeyEvent');
check(library.includes('event.type !== KeyType.Up'), 'KeyUp 分发（lxm.a(o,1) 等价）');
check(library.includes('matchKeyChord(event, ORIGIN_CHORD_NEW_NOTE)') &&
  library.includes('this.createAndOpen()'), 'Ctrl+N → mqa 建笔记等价');
check(library.includes('matchKeyChord(event, ORIGIN_CHORD_OPEN_SETTINGS)') &&
  library.includes('this.navigateToSettings()'), 'Ctrl+, → settings');
check(library.includes('matchKeyChord(event, ORIGIN_CHORD_BACK_TO_LIBRARY)') &&
  library.includes('this.selectFolder(null)'), 'Ctrl+L → All Notes 根');
check(library.includes('ORIGIN_CHORD_NEW_WINDOW') &&
  library.includes('ORIGIN_CHORD_OPEN_HELP'), '新窗口/帮助和弦消费登记');
check(/matchKeyChord\(event, ORIGIN_CHORD_DISMISS\)[\s\S]*?this\.isMultiSelecting[\s\S]*?this\.exitMultiSelect\(\)/.test(library),
  'ESC → 多选 deselect');
check(library.includes('.defaultFocus(true)'), 'Library 根焦点接管');

// ── NoteCanvasView：画布级 onKeyEvent（ofk.L 等价）──
check(canvas.includes('onCanvasKeyEvent'), '画布键盘处理器');
check(/\.onKeyEvent\(\(event: KeyEvent\): boolean => \{\s*return this\.onCanvasKeyEvent\(event\);/.test(canvas),
  '画布 Stack 挂 onKeyEvent');
check(canvas.includes('event.type === KeyType.Up'), '画布 KeyUp 分发');

// bd8.B 顶部分支：缩放三步 + 中心锚
check(canvas.includes('keyZoomBy(1.2)'), 'Ctrl+= → F(1.2f) 等价');
check(canvas.includes('keyZoomBy(0.8333333)'), 'Ctrl+- → F(0.8333333f) 等价');
check(/ORIGIN_ZOOM_RESET_KEYCODES[\s\S]*?keyZoomBy\(1\.0 \/ this\.viewport\.zoom\)/.test(canvas),
  'Ctrl+0 → mfc.D(1/current, center) 等价');
check(/private keyZoomBy\(factor: number\)[\s\S]*?this\.viewport\.zoomAt\(\s*this\.canvasCtx\.width \/ 2,\s*this\.canvasCtx\.height \/ 2/.test(canvas),
  '视口中心锚缩放');
check(canvas.includes('keyScrollToTop') && canvas.includes('keyScrollToBottom'),
  'Ctrl+Home/End 滚动');
check(/keyScrollToTop[\s\S]*?setScroll\(this\.viewport\.scrollX, 0\)/.test(canvas),
  'scrollToTop = scrollY→0');
check(/keyScrollToBottom[\s\S]*?canvasCtx\.height - this\.getPaperHeight\(\) \* this\.viewport\.zoom/.test(canvas),
  'scrollToBottom = 页底对齐视口底');

// 动作分支：Ctrl+F/E/P/R
check(/ctrl && shift && event\.keyCode === ORIGIN_KEYCODE_E[\s\S]*?this\.onKeyShowShare\(\)/.test(canvas),
  'Ctrl+Shift+E → rc8 ShowShare');
check(/ctrl && shift && event\.keyCode === ORIGIN_KEYCODE_P[\s\S]*?this\.onKeyOpenContentManager\(\)/.test(canvas),
  'Ctrl+Shift+P → oc8 OpenContentManager');
check(/ctrl && event\.keyCode === ORIGIN_KEYCODE_R[\s\S]*?this\.onKeyToggleRecording\(\)/.test(canvas),
  'Ctrl+R → sc8 ToggleRecording');
check(/ctrl && event\.keyCode === ORIGIN_KEYCODE_F[\s\S]*?this\.onKeyOpenSearch\(\)/.test(canvas),
  'Ctrl+F → pc8 OpenSearch');
check(canvas.includes('onKeyOpenSearch: () => void') &&
  canvas.includes('onKeyOpenContentManager: () => void') &&
  canvas.includes('onKeyShowShare: () => void') &&
  canvas.includes('onKeyToggleRecording: () => void'), 'ea1 总线回调上抛');

// f2 兜底链：rsi 门 + undo/redo + clipboard + 数字工具
check(canvas.includes('!this.textEditing'), 'rsi 门 = !textEditing');
check(/event\.keyCode === ORIGIN_KEYCODE_Z[\s\S]*?ORIGIN_KEYCODE_Y[\s\S]*?redoStroke\(\)[\s\S]*?undoStroke\(\)|ORIGIN_KEYCODE_Y[\s\S]*?this\.undoStroke\(\)|shift \|\| event\.keyCode === ORIGIN_KEYCODE_Y/.test(canvas),
  'Ctrl+Z undo / Ctrl+Shift+Z|Ctrl+Y redo');
check(canvas.includes('SelectionMenuAction.COPY') &&
  canvas.includes('ORIGIN_KEYCODE_C'), 'Ctrl+C → copy');
check(canvas.includes('SelectionMenuAction.CUT') &&
  canvas.includes('ORIGIN_KEYCODE_X'), 'Ctrl+X → cut');
check(/ORIGIN_KEYCODE_V[\s\S]*?clipboardAvailable[\s\S]*?SelectionMenuAction\.PASTE/.test(canvas),
  'Ctrl+V → paste（剪贴板可用门 + 视口中心定位）');
check(canvas.includes('toolSelectDigitIndex(event)') &&
  canvas.includes('selectVisibleToolByIndex'), 'Ctrl+1..9 → cxi 工具快选');
check(canvas.includes('visibleToolStates()') && canvas.includes('selectToolById'),
  '工具快选走 visibleToolStates 序');
check(/matchKeyChord\(event, ORIGIN_CHORD_DISMISS\)[\s\S]*?selectionTool\.getState\(\)\.isActive[\s\S]*?selectionTool\.deselect\(\)/.test(canvas),
  'ESC → 选区 deselect');
check(canvas.includes('.defaultFocus(true)'), '画布默认焦点');

// ── NotePage：应用级兜底 + 回调接线 ──
check(notePage.includes('onNoteAppKeyEvent'), '编辑器应用级处理器');
check(/\.onKeyEvent\(\(event: KeyEvent\): boolean => \{\s*return this\.onNoteAppKeyEvent\(event\);/.test(notePage),
  'NotePage 根挂 onKeyEvent');
check(/matchKeyChord\(event, ORIGIN_CHORD_OPEN_SETTINGS\)[\s\S]*?this\.navigateToSettings\(\)/.test(notePage),
  '编辑器 Ctrl+, → settings');
check(/matchKeyChord\(event, ORIGIN_CHORD_BACK_TO_LIBRARY\)[\s\S]*?this\.leaveEditor\(\)/.test(notePage),
  '编辑器 Ctrl+L → back_to_library = leaveEditor');
check(/ORIGIN_CHORD_OPEN_HELP[\s\S]*?showShortcutsHelp = true/.test(notePage),
  '编辑器 Ctrl+/ → qw6 帮助表（txm bindSheet 复刻，ADR-1358）');
check(/ORIGIN_CHORD_NEW_NOTE[\s\S]*?ORIGIN_CHORD_NEW_WINDOW/.test(notePage),
  '编辑器内 new_note/new_window 消费登记');
check(/ORIGIN_CHORD_DISMISS[\s\S]*?showShortcutsHelp[\s\S]*?docScanOpen[\s\S]*?showPageOverview/.test(notePage),
  'ESC → 帮助表 + sheet/cover dismiss 链');
check(notePage.includes('pageOverviewSearchSignal') && notePage.includes('toolbarShareSignal'),
  'Ctrl+F / Ctrl+Shift+E 页面侧信号声明');
check(notePage.includes('onKeyOpenSearch: ()') || notePage.includes('onKeyOpenSearch: (): void'),
  '画布 Ctrl+F 回调接线');
check(notePage.includes('searchSignal: this.pageOverviewSearchSignal'),
  'PageOverviewPanel searchSignal 接线');
check(notePage.includes('shareSignal: this.toolbarShareSignal'),
  'EditorToolbar shareSignal 接线');
check(/onKeyToggleRecording[\s\S]*?recordingSessionController[\s\S]*?isOriginalRecordingCaptureActive[\s\S]*?(startRecording|stopRecording)/.test(notePage),
  'Ctrl+R 录音切换（可用性门 + active 分支）');

// ── PageOverviewPanel / EditorToolbar 信号消费端 ──
check(panel.includes("@Prop @Watch('onSearchSignalChange') searchSignal"),
  '面板 searchSignal prop');
check(/onSearchSignalChange[\s\S]*?this\.searchActive = true/.test(panel),
  'Ctrl+F → searchActive=true');
check(panel.includes('.defaultFocus(true)'), '搜索框 defaultFocus');
check(toolbar.includes("@Prop @Watch('onShareSignalChange') shareSignal"),
  '工具条 shareSignal prop');
check(/onShareSignalChange[\s\S]*?this\.showShareSheet = true/.test(toolbar),
  'Ctrl+Shift+E → showShareSheet=true');

console.log(`d02-original-keyboard-shortcuts: ${n} checks OK`);
