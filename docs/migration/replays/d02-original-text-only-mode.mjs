// Phase 1395 — Text-only 视图模式（仅文本流式排版）。
// 原版证据（decompiled_1.4.2）：
//   strings.xml       — feature_note__options_menu_text_only "Text only"；
//                       text_only_banner_on/off_title/body + dismiss +
//                       text_only_auto_exit "Showing the full note"。
//   pdl.java:214      — ⋮ 选项菜单 onTextOnlyModeToggle(Z) 回调。
//   anb.java          — NoteStateEntity.isTextOnly 持久化列。
//   xf3.java:103/ymb  — is_text_only 专属 UPDATE。
//   x4i.java          — (isTextOnly, contentHeight, docWidth) → hrb：
//                       frb.Standard vs grb.TextOnly 双排版模式。
//   c5i.java          — 统一出口 b(q4i reason)。
//   q4i.java          — 退出原因枚举：ManualExit/SwitchedTools/InsertedImage/
//                       ImportedFile/InsertedSticky/OpenedContentManager/LegacyDaemon。
//   xqb.java:216      — SwitchedTools：eti 序数白名单 {4=TEXT,7=MEDIA,8=RECORD,
//                       9=POINTER} 外一切工具切换即退出。
//   d6b.java          — on/off 横幅 + auto-exit snackbar；横幅挂非文本元素门。
// Harmony 适配映射（ADR-1331）：
//   - eti TEXT 面 → ToolType.DEFAULT；保留集 → {DEFAULT}；
//   - 流式排版 → renderOrderedElements 前插 isTextOnly 分支 → renderTextOnlyFlow
//     用 cloneTextBlockElement 瞬态副本按页宽重排（不动持久化几何）；
//   - InsertedSticky/OpenedContentManager/LegacyDaemon 无对应路径 → 不适用；
//   - 流式视图为只读（beginTextEditingAt/toggleCheckboxMarkerAt 门控）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const REPO = 'note/src/main/ets/data/NoteRepositoryImpl.ets';
const IFACE = 'note/src/main/ets/data/RepositoryInterfaces.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const PAGE = 'note/src/main/ets/ui/editor/NotePage.ets';
const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const TEXT_RENDERER = 'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets';
const STRINGS_EN = 'note/src/main/resources/base/element/string.json';
const STRINGS_ZH = 'note/src/main/resources/zh_CN/element/string.json';

const repo = readFileSync(REPO, 'utf8');
const iface = readFileSync(IFACE, 'utf8');
const canvas = readFileSync(CANVAS, 'utf8');
const page = readFileSync(PAGE, 'utf8');
const vm = readFileSync(VM, 'utf8');
const textRenderer = readFileSync(TEXT_RENDERER, 'utf8');
const stringsEn = readFileSync(STRINGS_EN, 'utf8');
const stringsZh = readFileSync(STRINGS_ZH, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. 持久化（xf3/ymb 专属列写）===
check(/async saveIsTextOnly\(noteId: string, isTextOnly: boolean\)/.test(repo),
  'saveIsTextOnly signature');
check(/base\.isTextOnly = isTextOnly/.test(repo),
  'writer mutates preserved field then saveViewState (无丢列)');
check(/saveIsTextOnly\(noteId: string, isTextOnly: boolean\)/.test(iface),
  'interface exposes saveIsTextOnly');
check(/isTextOnly\??: boolean/.test(readFileSync(
  'note/src/main/ets/data/RepositoryInterfaces.ets', 'utf8')),
  'NoteViewState carries isTextOnly');

// === 2. 载入恢复（anb.g → hrb）===
check(/this\.isTextOnly = state\?\.isTextOnly === true/.test(canvas),
  'load seeds isTextOnly from note_state');
check(/isTextOnly && this\.viewModel\.currentTool !== ToolType\.DEFAULT[\s\S]{0,200}?selectTool\(ToolType\.DEFAULT\)/.test(canvas),
  'cold-open with isTextOnly=true forces DEFAULT tool (eti 保留集语义)');

// === 3. ⋮ 菜单项 + 信号链路 ===
check(/options_menu_text_only/.test(page), 'options menu has "Text only" row');
check(/menuicon_text/.test(page), 'menu row uses menuicon_text');
check(/action: \(\) => \{ this\.textOnlySignal\+\+; \}/.test(page),
  'menu row fires textOnlySignal');
check(/textOnlySignal: this\.textOnlySignal/.test(page) &&
  /textOnlyExitSignal: this\.textOnlyExitSignal/.test(page) &&
  /onTextOnlyStateChanged/.test(page),
  'canvas props wired (signal + exit + state callback)');
check(/@Prop @Watch\('onTextOnlySignalChange'\) textOnlySignal/.test(canvas) &&
  /@Prop @Watch\('onTextOnlyExitSignalChange'\) textOnlyExitSignal/.test(canvas),
  'canvas watches both signals');
check(/onTextOnlySignalChange\(_propName: string\): void \{[\s\S]{0,300}?setTextOnly\(!this\.isTextOnly/.test(canvas),
  'signal toggles setTextOnly');

// === 4. 流式排版（grb.TextOnly 等价）===
check(/if \(this\.isTextOnly\) \{[\s\S]{0,200}?renderTextOnlyFlow/.test(canvas),
  'renderFrame branches to text-only flow before layer-composite paths');
check(/private renderTextOnlyFlow\(renderContext: Canvas2DRenderContext\)/.test(canvas),
  'renderTextOnlyFlow exists');
check(/element\.kind !== PageElementKind\.TEXT[\s\S]{0,100}?continue/.test(canvas),
  'flow skips non-text elements (隐藏笔画/形状/图片/数学)');
check(/cloneTextBlockElement\(block\)/.test(canvas),
  'flow renders transient clones (持久化几何不变)');
check(/flowed\.blockWidth = flowWidth/.test(canvas) &&
  /flowed\.transform = \[1, 0, TEXT_ONLY_FLOW_MARGIN, 0, 1, cursorY, 0, 0, 1\]/.test(canvas),
  'flow reflows blocks at doc width + stacked cursor');
check(/measureTextHeight\(element: TextBlockElement, context: RenderContext\)/.test(textRenderer),
  'renderer exposes measureTextHeight (layoutLines 同口径行高)');

// === 5. 自动退出契约（q4i/c5i/xqb）===
check(/private onToolChangedForTextOnly\(tool: ToolType\)[\s\S]{0,200}?tool !== ToolType\.DEFAULT[\s\S]{0,100}?exitTextOnly\('SwitchedTools'\)/.test(canvas),
  'SwitchedTools: any non-DEFAULT tool exits (eti 白名单 → DEFAULT)');
check(/this\.viewModel\.onToolChanged = \(tool: ToolType\)[\s\S]{0,150}?onToolChangedForTextOnly/.test(canvas),
  'tool-change subscription wired in aboutToAppear');
check(/imported\.length > 0[\s\S]{0,100}?exitTextOnly\('InsertedImage'\)/.test(canvas),
  'InsertedImage: insertOriginalPhotos funnel exits');
check(/this\.textOnlyActive[\s\S]{0,100}?textOnlyExitSignal\+\+/.test(page),
  'ImportedFile: page-side import success fires exit signal');
check(/onTextOnlyExitSignalChange[\s\S]{0,150}?exitTextOnly/.test(canvas),
  'exit signal → c5i.b 统一出口');
check(/text_only_auto_exit/.test(canvas),
  'auto-exit shows "Showing the full note" toast (d6b snackbar)');

// === 6. 横幅 + 只读门 ===
check(/textOnlyBannerOn/.test(canvas) && /textOnlyBannerOff/.test(canvas),
  'on/off banner state');
check(/hasNonTextElements/.test(canvas) &&
  /completedStrokes\.length > 0 \|\| this\.shapes\.length > 0/.test(canvas),
  'banner gated on non-text elements (d6b z14 门)');
check(/dismissTextOnlyNotice/.test(canvas) && /dismissTextOnlyOffBanner/.test(canvas),
  'zkb dismiss callbacks');
check(/beginTextEditingAt\(position: Point2D\): void \{\s*if \(this\.photoImportBusy \|\| this\.historyBusy \|\| this\.isTextOnly\)/.test(canvas),
  'text editing gated off in text-only (只读流式视图)');
check(/toggleCheckboxMarkerAt[\s\S]{0,200}?this\.isTextOnly[\s\S]{0,50}?return false/.test(canvas),
  'checkbox toggle gated off in text-only');

// === 7. 资源（中英）===
for (const key of ['options_menu_text_only', 'text_only_banner_on_title',
  'text_only_banner_on_body', 'text_only_banner_dismiss',
  'text_only_banner_off_title', 'text_only_banner_off_body',
  'text_only_auto_exit']) {
  check(stringsEn.includes(`"name": "${key}"`), `en string ${key}`);
  check(stringsZh.includes(`"name": "${key}"`), `zh string ${key}`);
}
check(stringsEn.includes('"value": "Text only"'), 'en "Text only" label');
check(stringsEn.includes('"value": "Showing the full note"'), 'en auto-exit toast');
check(stringsEn.includes('"value": "Text only mode on"'), 'en banner on title');
check(stringsEn.includes('"value": "Text only mode off"'), 'en banner off title');

// === 8. VM 出口钩子 ===
check(/onToolChanged: \(tool: ToolType\) => void/.test(vm),
  'EditorViewModel.onToolChanged export');
check(/nextTool !== this\.currentTool[\s\S]{0,80}?onToolChanged\(nextTool\)/.test(vm),
  'applyActiveState emits onToolChanged');

console.log(`d02-original-text-only-mode OK — ${n} checks`);
