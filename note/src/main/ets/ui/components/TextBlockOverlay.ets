// T-024 文本框编辑覆盖层（TextArea 编辑态）
import { RichTextCharacterStyle, RichTextCharacterStyleRun, TextBlockElement, RichTextParagraphStyle, RichTextParagraphStyleRun } from '../../core/model/ElementTypes';
import { Point2D, Rect2D } from '../../core/model/GeometryTypes';
import { textBlockTransformComponents, TextBlockTransformComponents } from '../../core/model/TextBlockGeometry';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { registerNoteFonts } from '../../data/NoteFonts';
import { preferences } from '@kit.ArkData';

// 原版 rs1.d 代码块语言表（27 项，含 plaintext 哨兵 rs1.c——原版派单把
// plaintext 映射为 null=清除 programmingLanguage 字段）。
// 原版 qse.O 文字色板（i31 面板）的受限等价调色：与 ColorPickerView
// presetColors 同源的 12 色 ARGB 预设。
const TEXT_COLOR_PRESETS: number[] = [
  -16777216, -7829368, -65536, -26368, -256, -16744448,
  -16711681, -16776961, -8388480, -16181, -10011977, -1,
];

const CODE_LANGUAGES: string[][] = [
  ['bash', 'Bash'], ['c', 'C'], ['cpp', 'C++'], ['csharp', 'C#'],
  ['css', 'CSS'], ['go', 'Go'], ['haskell', 'Haskell'], ['java', 'Java'],
  ['javascript', 'JavaScript'], ['json', 'JSON'], ['kotlin', 'Kotlin'],
  ['lua', 'Lua'], ['markdown', 'Markdown'], ['markup', 'Markup'],
  ['matlab', 'Matlab'], ['objectivec', 'Objective-C'], ['ocaml', 'OCaml'],
  ['php', 'PHP'], ['plaintext', 'Plain Text'], ['python', 'Python'],
  ['r', 'R'], ['racket', 'Racket'], ['ruby', 'Ruby'], ['rust', 'Rust'],
  ['sql', 'SQL'], ['swift', 'Swift'], ['typescript', 'TypeScript'],
];

@Component
export struct TextBlockOverlay {
  @Prop editing: boolean = false;
  @Prop @Watch('onElementChange') element: TextBlockElement | null = null;
  @Prop screenOrigin: Point2D = { x: 0, y: 0 };
  @Prop screenBounds: Rect2D = { left: 0, top: 0, right: 0, bottom: 0 };
  @Prop viewportZoom: number = 1;
  @Prop layoutWidth: number = 0;
  @Prop photoImportLeaseActive: boolean = false;
  // 原版 pke（NoneActive）挂起保留 ake 会话：再激活同块恢复光标。
  // restoreCaret < 0 表示无挂起会话（新块/显式销毁后）。
  @Prop restoreCaret: number = -1;
  @State draftText: string = '';
  // 原版 h32 文本格式工具条（ADR-0647）：光标段落级 BLOCK_QUOTE(4)/CODE_BLOCK(5)
  // 切换；draftStyles 以段落序号为键承载编辑期样式，提交时折回字符区间 run。
  @State caretOffset: number = -1;
  @State caretDecoratorStyle: number = 0;
  private draftStyles: Map<number, RichTextParagraphStyle> = new Map();
  // 原版 l32/h32 字符样式（ADR-0648 同管线）：选区范围 run 级切换；
  // 折叠光标时进入 pending typing-attributes，其后输入字符按 pending 落地。
  @State caretSelectionStart: number = -1;
  @State caretCharBold: boolean = false;
  @State caretCharItalic: boolean = false;
  @State caretCharUnderline: boolean = false;
  @State caretCharStrike: boolean = false;
  @State caretCharSub: boolean = false;
  @State caretCharSuper: boolean = false;
  // 原版 bte/k5a：光标段落（decorator=5 时）代码语言选择态。
  @State caretCodeLanguage: string = 'plaintext';
  @State caretAlignment: number = 1;
  @State caretLineSpacing: number = 1;
  // 原版 rte/eh5：高亮态（选区全覆盖或 pending 含色）。
  @State caretCharHighlight: boolean = false;
  @State caretCharFontSize: number = 14;
  private pendingClearHighlight: boolean = false;
  // 原版 qte/ste：文字色 sheet 态与折叠清除标记。
  @State showTextColorSheet: boolean = false;
  @State showHsvSheet: boolean = false;
  @State hsvTarget: number = 0;             // 0=foreground(qte) 1=highlight(rte)
  @State colorRecents: number[] = [];
  @State hsvH: number = 0;
  @State hsvS: number = 0;
  @State hsvV: number = 0;
  private pendingClearForeground: boolean = false;
  // 原版 nte/zq8：折叠清除字体族标记。
  private pendingClearFamily: boolean = false;
  // 原版 tte/aue/en5：链接 sheet 态与草稿。
  @State showLinkSheet: boolean = false;
  @State linkUrlDraft: string = '';
  // 原版 en5.c：选区已带链接时对话框标题为 Edit hyperlink。
  @State linkSheetIsEdit: boolean = false;
  @State linkTitleDraft: string = '';
  private draftCharRuns: RichTextCharacterStyleRun[] = [];
  private pendingCharStyles: RichTextCharacterStyle = {};
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private controller: TextAreaController = new TextAreaController();
  onCommit: (text: string, characterStyleRuns: RichTextCharacterStyleRun[],
    paragraphStyleRuns: RichTextParagraphStyleRun[]) =>
    Promise<boolean> = async (_text: string,
      _charRuns: RichTextCharacterStyleRun[],
      _runs: RichTextParagraphStyleRun[]): Promise<boolean> => {
    return false;
  };
  onCancel: () => void = () => {
  };
  onDraftChange: (text: string) => void = () => {
  };
  onCaretChange: (offset: number) => void = (_offset: number) => {
  };

  aboutToAppear(): void {
    // 原版 qr4.c 三族字体注册（Inter/Roboto/EBGaramond）——
    // 进入文本编辑面前确保 canvas fontFamily 解析命中内置字库。
    registerNoteFonts(this.getUIContext());
    this.draftText = this.element !== null ? this.element.richText : '';
    this.seedParagraphStyles();
    this.loadColorRecents().catch((e: Error) => {
      console.error(`loadColorRecents failed: ${JSON.stringify(e)}`);
    });
  }

  onElementChange(): void {
    this.draftText = this.element !== null ? this.element.richText : '';
    this.seedParagraphStyles();
  }

  // 种子：把元素上的段落 run 解回“段落序号 → 样式”映射。换行插入/删除期间
  // 序号可能漂移——与原版一致的近似（原版同样按段落持样式）。
  private seedParagraphStyles(): void {
    this.draftStyles.clear();
    const runs: RichTextParagraphStyleRun[] = this.element !== null &&
      this.element.paragraphStyleRuns !== undefined ? this.element.paragraphStyleRuns : [];
    const text: string = this.element !== null ? this.element.richText : '';
    this.caretOffset = this.restoreCaret >= 0 ? Math.min(this.restoreCaret, text.length) :
      text.length;
    if (runs.length === 0) {
      this.caretDecoratorStyle = 0;
      this.caretCodeLanguage = 'plaintext';
      this.caretAlignment = 1;
      this.caretLineSpacing = 1;
      this.seedCharStyles();
      return;
    }
    let paragraphIndex: number = 0;
    let paragraphStart: number = 0;
    for (let index: number = 0; index <= text.length; index++) {
      if (index === text.length || text.charAt(index) === '\n') {
        const style: RichTextParagraphStyle = this.styleAtChar(runs, paragraphStart);
        if (Object.keys(style).length > 0) {
          this.draftStyles.set(paragraphIndex, style);
        }
        paragraphStart = index + 1;
        paragraphIndex++;
      }
    }
    this.caretDecoratorStyle = this.decoratorAt(this.caretOffset);
    this.refreshCaretCodeLanguage();
    this.refreshCaretParagraphExtras();
    this.seedCharStyles();
  }

  // 字符 run 种子：克隆元素既有 runs（编辑期 draft，提交时随 onCommit 回传）。
  private seedCharStyles(): void {
    const source: RichTextCharacterStyleRun[] = this.element !== null &&
      this.element.characterStyleRuns !== undefined ? this.element.characterStyleRuns : [];
    this.draftCharRuns = source.map((run: RichTextCharacterStyleRun):
      RichTextCharacterStyleRun => {
      const style: RichTextCharacterStyle =
        JSON.parse(JSON.stringify(run.style)) as RichTextCharacterStyle;
      return { start: run.start, end: run.end, style: style };
    });
    this.caretSelectionStart = this.caretOffset;
    this.pendingCharStyles = {};
    this.pendingClearHighlight = false;
    this.pendingClearForeground = false;
    this.pendingClearFamily = false;
    this.refreshCaretCharStyles();
  }

  private styleAtChar(runs: RichTextParagraphStyleRun[],
    offset: number): RichTextParagraphStyle {
    for (const run of runs) {
      if (offset >= run.start && offset < run.end) {
        return run.style;
      }
    }
    return {};
  }

  private paragraphIndexAt(offset: number): number {
    const clamped: number = Math.max(0, Math.min(offset, this.draftText.length));
    let index: number = 0;
    for (let i: number = 0; i < clamped; i++) {
      if (this.draftText.charAt(i) === '\n') {
        index++;
      }
    }
    return index;
  }

  private decoratorAt(offset: number): number {
    const style: RichTextParagraphStyle | undefined =
      this.draftStyles.get(this.paragraphIndexAt(offset));
    return style === undefined || style.decoratorStyle === undefined ? 0 :
      style.decoratorStyle;
  }

  private charStyleValue(style: RichTextCharacterStyle, field: string): boolean {
    if (field === 'bold') { return style.bold === true; }
    if (field === 'italic') { return style.italic === true; }
    if (field === 'underline') { return style.underline === true; }
    if (field === 'strikethrough') { return style.strikethrough === true; }
    if (field === 'subscript') { return style.subscript === true; }
    if (field === 'superscript') { return style.superscript === true; }
    return false;
  }

  // 字段是否显式存在（区分"未设置"与"显式 false"——pending 需要把
  // 显式 false 落地以清除同包互斥的兄弟字段）。
  private charStyleHas(style: RichTextCharacterStyle, field: string): boolean {
    if (field === 'bold') { return style.bold !== undefined; }
    if (field === 'italic') { return style.italic !== undefined; }
    if (field === 'underline') { return style.underline !== undefined; }
    if (field === 'strikethrough') { return style.strikethrough !== undefined; }
    if (field === 'subscript') { return style.subscript !== undefined; }
    if (field === 'superscript') { return style.superscript !== undefined; }
    if (field === 'highlightColor') { return style.highlightColor !== undefined; }
    return false;
  }

  private charStyleSet(style: RichTextCharacterStyle, field: string,
    value: boolean): void {
    if (field === 'bold') { style.bold = value; }
    else if (field === 'italic') { style.italic = value; }
    else if (field === 'underline') { style.underline = value; }
    else if (field === 'strikethrough') { style.strikethrough = value; }
    else if (field === 'subscript') { style.subscript = value; }
    else if (field === 'superscript') { style.superscript = value; }
  }

  // 选区是否被 field=true 的 run 完全覆盖（原版 br2 全量态取反的等价判定）。
  private rangeHasCharStyle(field: string, s: number, e: number): boolean {
    const covering: RichTextCharacterStyleRun[] = this.draftCharRuns
      .filter((r: RichTextCharacterStyleRun): boolean =>
        r.end > s && r.start < e && this.charStyleValue(r.style, field))
      .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
        a.start - b.start);
    let pos: number = s;
    for (const run of covering) {
      if (run.start > pos) {
        return false;
      }
      pos = Math.max(pos, run.end);
      if (pos >= e) {
        return true;
      }
    }
    return false;
  }

  // 把 [s,e) 范围内的 field 统一设为 value：边界切分、内段改样式、空洞补新 run。
  private applyCharStyle(field: string, value: boolean, s: number, e: number): void {
    const next: RichTextCharacterStyleRun[] = [];
    for (const run of this.draftCharRuns) {
      if (run.end <= s || run.start >= e) {
        next.push(run);
        continue;
      }
      if (run.start < s) {
        next.push({ start: run.start, end: s, style: run.style });
      }
      if (run.end > e) {
        next.push({ start: e, end: run.end, style: run.style });
      }
      const mid: RichTextCharacterStyle =
        JSON.parse(JSON.stringify(run.style)) as RichTextCharacterStyle;
      this.charStyleSet(mid, field, value);
      next.push({ start: Math.max(s, run.start), end: Math.min(e, run.end),
        style: mid });
    }
    const inside: RichTextCharacterStyleRun[] = next
      .filter((r: RichTextCharacterStyleRun): boolean => r.start < e && r.end > s)
      .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
        a.start - b.start);
    let pos: number = s;
    for (const run of inside) {
      if (run.start > pos) {
        const st: RichTextCharacterStyle = {};
        this.charStyleSet(st, field, value);
        next.push({ start: pos, end: run.start, style: st });
      }
      pos = Math.max(pos, run.end);
    }
    if (pos < e) {
      const st: RichTextCharacterStyle = {};
      this.charStyleSet(st, field, value);
      next.push({ start: pos, end: e, style: st });
    }
    this.draftCharRuns = next;
  }

  // 排序、去空段、合并相邻同样式 run（canonical form，diff 稳定）。
  private normalizeCharRuns(): void {
    const sorted: RichTextCharacterStyleRun[] = this.draftCharRuns
      .filter((r: RichTextCharacterStyleRun): boolean =>
        r.end > r.start && JSON.stringify(r.style) !== '{}')
      .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
        a.start - b.start || a.end - b.end);
    const merged: RichTextCharacterStyleRun[] = [];
    for (const run of sorted) {
      const last: RichTextCharacterStyleRun | undefined =
        merged.length > 0 ? merged[merged.length - 1] : undefined;
      if (last !== undefined && last.end === run.start &&
        JSON.stringify(last.style) === JSON.stringify(run.style)) {
        last.end = run.end;
      } else {
        merged.push(run);
      }
    }
    this.draftCharRuns = merged;
  }

  // 文本编辑后按公共前后缀差分平移/收缩 run 边界；返回编辑起点供 pending
  // typing-attributes 落地定位。
  private adjustCharRunsForEdit(newText: string, oldText: string): number {
    let prefix: number = 0;
    const maxPrefix: number = Math.min(oldText.length, newText.length);
    while (prefix < maxPrefix && oldText.charAt(prefix) === newText.charAt(prefix)) {
      prefix++;
    }
    let suffix: number = 0;
    const maxSuffix: number = Math.min(oldText.length - prefix,
      newText.length - prefix);
    while (suffix < maxSuffix &&
      oldText.charAt(oldText.length - 1 - suffix) ===
        newText.charAt(newText.length - 1 - suffix)) {
      suffix++;
    }
    const delStart: number = prefix;
    const delEnd: number = oldText.length - suffix;
    const delta: number = newText.length - oldText.length;
    const next: RichTextCharacterStyleRun[] = [];
    for (const run of this.draftCharRuns) {
      if (run.end <= delStart) {
        next.push(run);
        continue;
      }
      if (run.start >= delEnd) {
        next.push({ start: run.start + delta, end: run.end + delta,
          style: run.style });
        continue;
      }
      const ns: number = run.start < delStart ? run.start : delStart;
      const ne: number = run.end > delEnd ? run.end + delta : delStart;
      if (ne > ns) {
        next.push({ start: ns, end: ne, style: run.style });
      }
    }
    this.draftCharRuns = next;
    return delStart;
  }

  private refreshCaretCharStyles(): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    if (s === e) {
      this.caretCharBold = this.charStyleValue(this.pendingCharStyles, 'bold');
      this.caretCharItalic = this.charStyleValue(this.pendingCharStyles, 'italic');
      this.caretCharUnderline = this.charStyleValue(this.pendingCharStyles, 'underline');
      this.caretCharStrike = this.charStyleValue(this.pendingCharStyles, 'strikethrough');
      this.caretCharSub = this.charStyleValue(this.pendingCharStyles, 'subscript');
      this.caretCharSuper = this.charStyleValue(this.pendingCharStyles, 'superscript');
      this.caretCharHighlight = this.pendingCharStyles.highlightColor !== undefined &&
        !this.pendingClearHighlight;
      this.caretCharFontSize = this.pendingCharStyles.fontSize ??
        this.fontSizeNearCaret() ??
        (this.element !== null ? this.element.fontSize : 14);
      return;
    }
    this.caretCharBold = this.rangeHasCharStyle('bold', s, e);
    this.caretCharItalic = this.rangeHasCharStyle('italic', s, e);
    this.caretCharUnderline = this.rangeHasCharStyle('underline', s, e);
    this.caretCharStrike = this.rangeHasCharStyle('strikethrough', s, e);
    this.caretCharSub = this.rangeHasCharStyle('subscript', s, e);
    this.caretCharSuper = this.rangeHasCharStyle('superscript', s, e);
    this.caretCharHighlight = this.rangeHasHighlight(s, e);
    this.caretCharFontSize = this.fontSizeAt(s, e);
  }

  // 原版 l32/h32 字符样式切换：选区非空时按覆盖态取反改写选区 run；
  // 折叠光标时翻 pending typing-attributes（其后输入按 pending 落地）。
  private toggleCharStyle(field: string): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    if (s === e) {
      const current: boolean = this.charStyleValue(this.pendingCharStyles, field);
      this.charStyleSet(this.pendingCharStyles, field, !current);
      this.refreshCaretCharStyles();
      return;
    }
    this.applyCharStyle(field, !this.rangeHasCharStyle(field, s, e), s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 选区是否被 highlightColor 非空的 run 完全覆盖。
  private rangeHasHighlight(s: number, e: number): boolean {
    const covering: RichTextCharacterStyleRun[] = this.draftCharRuns
      .filter((r: RichTextCharacterStyleRun): boolean =>
        r.end > s && r.start < e && r.style.highlightColor !== undefined)
      .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
        a.start - b.start);
    let pos: number = s;
    for (const run of covering) {
      if (run.start > pos) {
        return false;
      }
      pos = Math.max(pos, run.end);
      if (pos >= e) {
        return true;
      }
    }
    return false;
  }

  // 原版 rte：把高亮色写入选区（color===null 即 Remove Highlight 清除字段）。
  private applyHighlightColor(color: number | null, s: number, e: number): void {
    const next: RichTextCharacterStyleRun[] = [];
    for (const run of this.draftCharRuns) {
      if (run.end <= s || run.start >= e) {
        next.push(run);
        continue;
      }
      if (run.start < s) {
        next.push({ start: run.start, end: s, style: run.style });
      }
      if (run.end > e) {
        next.push({ start: e, end: run.end, style: run.style });
      }
      const mid: RichTextCharacterStyle =
        JSON.parse(JSON.stringify(run.style)) as RichTextCharacterStyle;
      mid.highlightColor = color === null ? undefined : color;
      next.push({ start: Math.max(s, run.start), end: Math.min(e, run.end),
        style: mid });
    }
    if (color !== null) {
      const inside: RichTextCharacterStyleRun[] = next
        .filter((r: RichTextCharacterStyleRun): boolean => r.start < e && r.end > s)
        .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
          a.start - b.start);
      let pos: number = s;
      for (const run of inside) {
        if (run.start > pos) {
          next.push({ start: pos, end: run.start,
            style: { highlightColor: color } });
        }
        pos = Math.max(pos, run.end);
      }
      if (pos < e) {
        next.push({ start: pos, end: e, style: { highlightColor: color } });
      }
    }
    this.draftCharRuns = next;
  }

  // 原版 rte 点按=把当前色板色应用到选区/写入 pending（eh5{iu1,true}）。
  private toggleHighlightColor(color: number): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    this.recordRecentColor(color);
    if (s === e) {
      this.pendingCharStyles.highlightColor = color;
      this.pendingClearHighlight = false;
      this.refreshCaretCharStyles();
      return;
    }
    this.applyHighlightColor(color, s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 原版 feature_note__selection_menu_remove_highlight：清除选区/预期高亮。
  private clearHighlight(): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    if (s === e) {
      this.pendingClearHighlight = true;
      this.refreshCaretCharStyles();
      return;
    }
    this.applyHighlightColor(null, s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 高亮菜单：五色预设 + Remove Highlight（原版 rte 弹色板的受限等价）。
  private buildHighlightMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    items.push({ value: $r('app.string.highlight_yellow'),
      action: (): void => {
        this.toggleHighlightColor(1716898048);
      } });
    items.push({ value: $r('app.string.highlight_green'),
      action: (): void => {
        this.toggleHighlightColor(1713702656);
      } });
    items.push({ value: $r('app.string.highlight_cyan'),
      action: (): void => {
        this.toggleHighlightColor(1711276032);
      } });
    items.push({ value: $r('app.string.highlight_pink'),
      action: (): void => {
        this.toggleHighlightColor(1717973195);
      } });
    items.push({ value: $r('app.string.highlight_orange'),
      action: (): void => {
        this.toggleHighlightColor(1717994752);
      } });
    items.push({ value: $r('app.string.color_custom'),
      action: (): void => {
        this.openHsvSheet(1);
      } });
    items.push({ value: $r('app.string.highlight_remove'),
      action: (): void => {
        this.clearHighlight();
      } });
    return items;
  }

  // 原版 kre/pte：选区（或折叠 pending）当前字号 —— 选区取首个携
  // fontSize run 的值，否则回落 element.fontSize（块缺省）。
  private fontSizeAt(s: number, e: number): number {
    for (const run of this.draftCharRuns) {
      if (run.end <= s || run.start >= e) {
        continue;
      }
      if (run.style.fontSize !== undefined) {
        return run.style.fontSize;
      }
    }
    return this.element !== null ? this.element.fontSize : 14;
  }

  // 折叠光标的"当前字号"：优先 pending typing-attributes，其次光标处
  // run（start<caret<=end，与插入落点语义一致）。
  private fontSizeNearCaret(): number | undefined {
    for (const run of this.draftCharRuns) {
      if (run.start < this.caretOffset && this.caretOffset <= run.end &&
        run.style.fontSize !== undefined) {
        return run.style.fontSize;
      }
    }
    return undefined;
  }

  // 原版 cve l(f±1)：zyd.f=Float(rh8.u(f,4,72)) —— kre 步进钮 ±1pt，
  // clamp [4,72]；选区写 run、折叠写 pending（与其他字符样式同路径）。
  private stepFontSize(delta: number): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    const current: number = s === e ?
      (this.pendingCharStyles.fontSize ?? this.fontSizeNearCaret() ??
        (this.element !== null ? this.element.fontSize : 14)) :
      this.fontSizeAt(s, e);
    const next: number = Math.max(4, Math.min(72, current + delta));
    if (s === e) {
      this.pendingCharStyles.fontSize = next;
      this.refreshCaretCharStyles();
      return;
    }
    this.applyFontSize(next, s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 原版 cve l(f)：zyd.f=Float(rh8.u(f,4,72)) —— 字号字段区间写（clamp
  // [4,72] 在预设表侧已固定，本方法直接落值；size===null 清除字段）。
  private applyFontSize(size: number | null, s: number, e: number): void {
    const next: RichTextCharacterStyleRun[] = [];
    for (const run of this.draftCharRuns) {
      if (run.end <= s || run.start >= e) {
        next.push(run);
        continue;
      }
      if (run.start < s) {
        next.push({ start: run.start, end: s, style: run.style });
      }
      if (run.end > e) {
        next.push({ start: e, end: run.end, style: run.style });
      }
      const mid: RichTextCharacterStyle =
        JSON.parse(JSON.stringify(run.style)) as RichTextCharacterStyle;
      mid.fontSize = size === null ? undefined : size;
      next.push({ start: Math.max(s, run.start), end: Math.min(e, run.end),
        style: mid });
    }
    if (size !== null) {
      const inside: RichTextCharacterStyleRun[] = next
        .filter((r: RichTextCharacterStyleRun): boolean => r.start < e && r.end > s)
        .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
          a.start - b.start);
      let pos: number = s;
      for (const run of inside) {
        if (run.start > pos) {
          next.push({ start: pos, end: run.start, style: { fontSize: size } });
        }
        pos = Math.max(pos, run.end);
      }
      if (pos < e) {
        next.push({ start: pos, end: e, style: { fontSize: size } });
      }
    }
    this.draftCharRuns = next;
  }

  // 原版 cve ote：zyd{hr4.I(bold), italic=FALSE, hr4.J(fontSize)} mask2012
  // —— 样式预设原子写三字段（bold 随预设、italic 显式清除、字号预设值）。
  private applyTextStylePreset(bold: boolean, fontSize: number): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    if (s === e) {
      this.pendingCharStyles.bold = bold;
      this.pendingCharStyles.italic = false;
      this.pendingCharStyles.fontSize = fontSize;
      this.refreshCaretCharStyles();
      return;
    }
    const next: RichTextCharacterStyleRun[] = [];
    for (const run of this.draftCharRuns) {
      if (run.end <= s || run.start >= e) {
        next.push(run);
        continue;
      }
      if (run.start < s) {
        next.push({ start: run.start, end: s, style: run.style });
      }
      if (run.end > e) {
        next.push({ start: e, end: run.end, style: run.style });
      }
      const mid: RichTextCharacterStyle =
        JSON.parse(JSON.stringify(run.style)) as RichTextCharacterStyle;
      mid.bold = bold;
      mid.italic = false;
      mid.fontSize = fontSize;
      next.push({ start: Math.max(s, run.start), end: Math.min(e, run.end),
        style: mid });
    }
    const inside: RichTextCharacterStyleRun[] = next
      .filter((r: RichTextCharacterStyleRun): boolean => r.start < e && r.end > s)
      .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
        a.start - b.start);
    let pos: number = s;
    for (const run of inside) {
      if (run.start > pos) {
        next.push({ start: pos, end: run.start,
          style: { bold: bold, italic: false, fontSize: fontSize } });
      }
      pos = Math.max(pos, run.end);
    }
    if (pos < e) {
      next.push({ start: pos, end: e,
        style: { bold: bold, italic: false, fontSize: fontSize } });
    }
    this.draftCharRuns = next;
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 原版 hr4 预设表（i31 字体样式面板）：LargeTitle36b/H1 30b/H2 24b/
  // H3 18b/Body 14(K=缺省)/Caption 12。
  private buildTextStyleMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    items.push({ value: $r('app.string.font_style_large_title'),
      action: (): void => {
        this.applyTextStylePreset(true, 36);
      } });
    items.push({ value: $r('app.string.font_style_heading_1'),
      action: (): void => {
        this.applyTextStylePreset(true, 30);
      } });
    items.push({ value: $r('app.string.font_style_heading_2'),
      action: (): void => {
        this.applyTextStylePreset(true, 24);
      } });
    items.push({ value: $r('app.string.font_style_heading_3'),
      action: (): void => {
        this.applyTextStylePreset(true, 18);
      } });
    items.push({ value: $r('app.string.font_style_body'),
      action: (): void => {
        this.applyTextStylePreset(false, 14);
      } });
    items.push({ value: $r('app.string.font_style_caption'),
      action: (): void => {
        this.applyTextStylePreset(false, 12);
      } });
    return items;
  }

  // 原版 qte/ste：把文字色写入选区（color===null 即恢复 element.fontColor
  // 缺省色——字段清除，等价于"未指定"）。
  private applyForegroundColor(color: number | null, s: number, e: number): void {
    const next: RichTextCharacterStyleRun[] = [];
    for (const run of this.draftCharRuns) {
      if (run.end <= s || run.start >= e) {
        next.push(run);
        continue;
      }
      if (run.start < s) {
        next.push({ start: run.start, end: s, style: run.style });
      }
      if (run.end > e) {
        next.push({ start: e, end: run.end, style: run.style });
      }
      const mid: RichTextCharacterStyle =
        JSON.parse(JSON.stringify(run.style)) as RichTextCharacterStyle;
      mid.foregroundColor = color === null ? undefined : color;
      next.push({ start: Math.max(s, run.start), end: Math.min(e, run.end),
        style: mid });
    }
    if (color !== null) {
      const inside: RichTextCharacterStyleRun[] = next
        .filter((r: RichTextCharacterStyleRun): boolean => r.start < e && r.end > s)
        .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
          a.start - b.start);
      let pos: number = s;
      for (const run of inside) {
        if (run.start > pos) {
          next.push({ start: pos, end: run.start,
            style: { foregroundColor: color } });
        }
        pos = Math.max(pos, run.end);
      }
      if (pos < e) {
        next.push({ start: pos, end: e, style: { foregroundColor: color } });
      }
    }
    this.draftCharRuns = next;
  }

  // 原版 qte 取色确认：选区写 foregroundColor run / 折叠光标写 pending。
  private pickTextColor(color: number): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    this.recordRecentColor(color);
    this.showTextColorSheet = false;
    if (s === e) {
      this.pendingCharStyles.foregroundColor = color;
      this.pendingClearForeground = false;
      this.refreshCaretCharStyles();
      return;
    }
    this.applyForegroundColor(color, s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // "Automatic"——恢复元素缺省字色（foregroundColor 字段清除）。
  private clearTextColor(): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    this.showTextColorSheet = false;
    if (s === e) {
      this.pendingClearForeground = true;
      this.refreshCaretCharStyles();
      return;
    }
    this.applyForegroundColor(null, s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 原版 zw1/sw1/ms0 最近色：bhb 记录→sw1{recentColors} 面板行（7 槽
  // 上限）。Harmony 持久化到 preferences 'text_color_recents'，
  // 前景/高亮两面板共享一份（与原版同一 rw1 面板语义一致）。
  private async loadColorRecents(): Promise<void> {
    const store = await preferences.getPreferences(
      getContext(this), 'text_color_recents');
    const raw: preferences.ValueType = store.getSync('recents', '[]');
    const list: number[] =
      JSON.parse(typeof raw === 'string' ? raw : '[]') as number[];
    this.colorRecents = list
      .filter((v: number): boolean => typeof v === 'number')
      .slice(0, 7);
  }

  private recordRecentColor(color: number): void {
    this.colorRecents =
      [color, ...this.colorRecents.filter((c: number): boolean => c !== color)]
        .slice(0, 7);
    this.saveColorRecents().catch((e: Error) => {
      console.error(`saveColorRecents failed: ${JSON.stringify(e)}`);
    });
  }

  private async saveColorRecents(): Promise<void> {
    const store = await preferences.getPreferences(
      getContext(this), 'text_color_recents');
    store.putSync('recents', JSON.stringify(this.colorRecents));
    await store.flush();
  }

  // 最近色点按：按当前 hsvTarget 分派前景/高亮管线（命中项自动前移）。
  private pickRecentColor(color: number): void {
    this.showHsvSheet = false;
    if (this.hsvTarget === 1) {
      this.toggleHighlightColor(color);
    } else {
      this.pickTextColor(color);
    }
  }

  // 最近色行（rw1.f 等价）：仅在有记录时渲染。
  @Builder
  private buildColorRecentsRow(): void {
    if (this.colorRecents.length > 0) {
      Row() {
        ForEach(this.colorRecents, (color: number) => {
          Column()
            .width(24)
            .height(24)
            .borderRadius(12)
            .backgroundColor(color)
            .border({ width: 1, color: this.resolveTokens().border })
            .margin({ right: 8 })
            .enabled(!this.photoImportLeaseActive)
            .onClick(() => {
              this.pickRecentColor(color);
            })
        }, (color: number) => 'recent:' + color.toString())
      }
      .margin({ bottom: 12 })
    }
  }

  // 原版 ru1=ColorHSV(h,s,v)/te5.B：HSV→ARGB（alpha=FF），纯函数。
  private hsvComponentsToArgb(h: number, s: number, v: number): number {
    const hue: number = ((h % 360) + 360) % 360;
    const c: number = v * s;
    const x: number = c * (1 - Math.abs(((hue / 60) % 2) - 1));
    const m: number = v - c;
    let r: number = 0; let g: number = 0; let b: number = 0;
    if (hue < 60) { r = c; g = x; } else if (hue < 120) { r = x; g = c; }
    else if (hue < 180) { g = c; b = x; } else if (hue < 240) { g = x; b = c; }
    else if (hue < 300) { r = x; b = c; } else { r = c; b = x; }
    return -16777216 |
      (Math.round((r + m) * 255) << 16) |
      (Math.round((g + m) * 255) << 8) |
      Math.round((b + m) * 255);
  }

  private hsvToArgb(): number {
    return this.hsvComponentsToArgb(this.hsvH, this.hsvS, this.hsvV);
  }

  // 纯色相（hsv(h,1,1)）——SV 方盘底色与色相条拇指色。
  private hueBaseColor(): number {
    return this.hsvComponentsToArgb(this.hsvH, 1, 1);
  }

  // Color.RGBToHSV 等价：ARGB int → h/s/v 三态（打开面板时种子色）。
  private seedHsvFromArgb(argb: number): void {
    const r: number = ((argb >> 16) & 255) / 255;
    const g: number = ((argb >> 8) & 255) / 255;
    const b: number = (argb & 255) / 255;
    const max: number = Math.max(r, Math.max(g, b));
    const min: number = Math.min(r, Math.min(g, b));
    const d: number = max - min;
    this.hsvV = max;
    this.hsvS = max === 0 ? 0 : d / max;
    if (d === 0) {
      this.hsvH = 0;
    } else if (max === r) {
      this.hsvH = (60 * (((g - b) / d) % 6) + 360) % 360;
    } else if (max === g) {
      this.hsvH = 60 * (((b - r) / d) + 2);
    } else {
      this.hsvH = 60 * (((r - g) / d) + 4);
    }
  }

  // 当前色（种子）：foreground 取选区首个 foregroundColor run 否则元素
  // 字色；highlight 取首个 highlightColor run 否则默认黄色。
  private hsvSeedColor(): number {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    const field: string = this.hsvTarget === 1 ? 'highlightColor' : 'foregroundColor';
    for (const run of this.draftCharRuns) {
      if (run.end > s && run.start < e) {
        const v: number | undefined =
          field === 'highlightColor' ? run.style.highlightColor : run.style.foregroundColor;
        if (v !== undefined) {
          return v;
        }
      }
    }
    return this.hsvTarget === 1 ? 1716898048 : -16777216;
  }

  private openHsvSheet(target: number): void {
    this.hsvTarget = target;
    this.seedHsvFromArgb(this.hsvSeedColor());
    this.showTextColorSheet = false;
    this.showHsvSheet = true;
  }

  private confirmHsvColor(): void {
    const color: number = this.hsvToArgb();
    this.showHsvSheet = false;
    if (this.hsvTarget === 1) {
      this.toggleHighlightColor(color);
    } else {
      this.pickTextColor(color);
    }
  }

  // 原版 rw1.g("ColorPicker")→t8j：HSV 子面板——SV 方盘（横向白→透明 +
  // 纵向透明→黑叠加在纯色色相底上）、色相条（6 停点彩虹渐变）、
  // 预览色 + Apply/Cancel。拖拽语义 = q8e pointerInput 分区内取坐标比例。
  @Builder
  private buildHsvSheet(): void {
    Column() {
      // 预览 + 当前 RGB
      Row() {
        Column()
          .width(40)
          .height(28)
          .borderRadius(6)
          .backgroundColor(this.hsvToArgb())
          .border({ width: 1, color: this.resolveTokens().border })
        Text('H ' + Math.round(this.hsvH).toString() +
          '  S ' + Math.round(this.hsvS * 100).toString() + '%' +
          '  V ' + Math.round(this.hsvV * 100).toString() + '%')
          .fontSize(12)
          .fontColor(this.element !== null ? this.element.fontColor : '#000000')
          .margin({ left: 10 })
      }
      .margin({ bottom: 12 })
      // SV 方盘：色相底 + 横向白→透明（sat）+ 纵向透明→黑（val）。
      Stack() {
        Column()
          .width(240)
          .height(160)
          .backgroundColor(this.hueBaseColor())
        Column()
          .width(240)
          .height(160)
          .linearGradient({ angle: 90,
            colors: [[0xFFFFFFFF, 0.0], [0x00FFFFFF, 1.0]] })
        Column()
          .width(240)
          .height(160)
          .linearGradient({ angle: 180,
            colors: [[0x00000000, 0.0], [0xFF000000, 1.0]] })
        Column()
          .width(12)
          .height(12)
          .borderRadius(6)
          .backgroundColor(this.hsvToArgb())
          .border({ width: 2, color: 0xFFFFFFFF })
          .position({ x: this.hsvS * 240 - 6, y: (1 - this.hsvV) * 160 - 6 })
      }
      .alignContent(Alignment.TopStart)
      .width(240)
      .height(160)
      .borderRadius(8)
      .clip(true)
      .enabled(!this.photoImportLeaseActive)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down || event.type === TouchType.Move) {
          const t: TouchObject = event.touches[0];
          this.hsvS = Math.max(0, Math.min(1, t.x / 240));
          this.hsvV = 1 - Math.max(0, Math.min(1, t.y / 160));
        }
      })
      .margin({ bottom: 12 })
      // 色相条：彩虹渐变 + 拇指。
      Stack() {
        Column()
          .width(240)
          .height(18)
          .linearGradient({ angle: 90, colors: [
            [0xFFFF0000, 0.0], [0xFFFFFF00, 0.167], [0xFF00FF00, 0.333],
            [0xFF00FFFF, 0.5], [0xFF0000FF, 0.667], [0xFFFF00FF, 0.833],
            [0xFFFF0000, 1.0]] })
        Column()
          .width(12)
          .height(18)
          .borderRadius(6)
          .backgroundColor(this.hueBaseColor())
          .border({ width: 2, color: 0xFFFFFFFF })
          .position({ x: (this.hsvH / 360) * 240 - 6, y: 0 })
      }
      .alignContent(Alignment.TopStart)
      .width(240)
      .height(18)
      .borderRadius(9)
      .clip(true)
      .enabled(!this.photoImportLeaseActive)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down || event.type === TouchType.Move) {
          const t: TouchObject = event.touches[0];
          this.hsvH = Math.max(0, Math.min(359.99,
            (t.x / 240) * 360));
        }
      })
      .margin({ bottom: 16 })
      this.buildColorRecentsRow()
      Row() {
        Button($r('app.string.color_apply'))
          .height(32)
          .fontSize(12)
          .backgroundColor(this.resolveTokens().accent)
          .fontColor('#FFFFFF')
          .enabled(!this.photoImportLeaseActive)
          .onClick(() => {
            this.confirmHsvColor();
          })
        Button($r('app.string.cancel'))
          .height(32)
          .fontSize(12)
          .backgroundColor(this.resolveTokens().surface)
          .fontColor(this.element !== null ? this.element.fontColor : '#000000')
          .margin({ left: 12 })
          .onClick(() => {
            this.showHsvSheet = false;
          })
      }
    }
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
  }

  // 文字色板 sheet：12 色预设网格 + Automatic（受限等价 qse.O 面板）。
  @Builder
  private buildTextColorSheet(): void {
    Column() {
      Grid() {
        ForEach(TEXT_COLOR_PRESETS, (color: number) => {
          GridItem() {
            Column()
              .width(32)
              .height(32)
              .borderRadius(16)
              .backgroundColor(color)
              .border({ width: 1, color: this.resolveTokens().border })
              .enabled(!this.photoImportLeaseActive)
              .onClick(() => {
                this.pickTextColor(color);
              })
          }
        }, (color: number) => 'fg:' + color.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width(200)
      .margin({ bottom: 16 })
      this.buildColorRecentsRow()
      Row() {
        Button($r('app.string.color_automatic'))
          .height(32)
          .fontSize(12)
          .backgroundColor(this.resolveTokens().surface)
          .fontColor(this.element !== null ? this.element.fontColor : '#000000')
          .enabled(!this.photoImportLeaseActive)
          .onClick(() => {
            this.clearTextColor();
          })
        // 原版 mli.c→rw1.c 面板内嵌 HSV 取色器入口。
        Button($r('app.string.color_custom'))
          .height(32)
          .fontSize(12)
          .backgroundColor(this.resolveTokens().surface)
          .fontColor(this.element !== null ? this.element.fontColor : '#000000')
          .enabled(!this.photoImportLeaseActive)
          .margin({ left: 12 })
          .onClick(() => {
            this.openHsvSheet(0);
          })
      }
    }
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
  }

  // 原版 nte：zq8.a(modelName) → zyd.e 写选区字体族；name===null 即
  // 字段清除（回退元素缺省字体，等价 qr4.b=Inter 缺省语义）。
  private applyFontFamily(name: string | null, s: number, e: number): void {
    const next: RichTextCharacterStyleRun[] = [];
    for (const run of this.draftCharRuns) {
      if (run.end <= s || run.start >= e) {
        next.push(run);
        continue;
      }
      if (run.start < s) {
        next.push({ start: run.start, end: s, style: run.style });
      }
      if (run.end > e) {
        next.push({ start: e, end: run.end, style: run.style });
      }
      const mid: RichTextCharacterStyle =
        JSON.parse(JSON.stringify(run.style)) as RichTextCharacterStyle;
      mid.familyName = name === null ? undefined : name;
      next.push({ start: Math.max(s, run.start), end: Math.min(e, run.end),
        style: mid });
    }
    if (name !== null) {
      const inside: RichTextCharacterStyleRun[] = next
        .filter((r: RichTextCharacterStyleRun): boolean => r.start < e && r.end > s)
        .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
          a.start - b.start);
      let pos: number = s;
      for (const run of inside) {
        if (run.start > pos) {
          next.push({ start: pos, end: run.start, style: { familyName: name } });
        }
        pos = Math.max(pos, run.end);
      }
      if (pos < e) {
        next.push({ start: pos, end: e, style: { familyName: name } });
      }
    }
    this.draftCharRuns = next;
  }

  // 原版 i31 字体族项 → new nte(zq8Var)：选区写 familyName / 折叠写 pending。
  private pickFontFamily(name: string): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    if (s === e) {
      this.pendingCharStyles.familyName = name;
      this.pendingClearFamily = false;
      this.refreshCaretCharStyles();
      return;
    }
    this.applyFontFamily(name, s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // "Default"——恢复缺省字体（familyName 字段清除）。
  private clearFontFamily(): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    if (s === e) {
      this.pendingClearFamily = true;
      this.refreshCaretCharStyles();
      return;
    }
    this.applyFontFamily(null, s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 原版 qr4.c/d 三随包字体（modelName 落库、displayName 展示）+ Default。
  private buildFontMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    items.push({ value: 'Inter',
      action: (): void => {
        this.pickFontFamily('Inter');
      } });
    items.push({ value: 'Roboto',
      action: (): void => {
        this.pickFontFamily('Roboto');
      } });
    items.push({ value: 'EB Garamond',
      action: (): void => {
        this.pickFontFamily('EBGaramond');
      } });
    items.push({ value: $r('app.string.font_default'),
      action: (): void => {
        this.clearFontFamily();
      } });
    return items;
  }

  // 原版 zyd.h：link 字段区间写（url===null 即 aue/wm5→
  // removeHyperlinkFromSelection 的清除语义）。
  private applyLinkUrl(url: string | null, s: number, e: number): void {
    const next: RichTextCharacterStyleRun[] = [];
    for (const run of this.draftCharRuns) {
      if (run.end <= s || run.start >= e) {
        next.push(run);
        continue;
      }
      if (run.start < s) {
        next.push({ start: run.start, end: s, style: run.style });
      }
      if (run.end > e) {
        next.push({ start: e, end: run.end, style: run.style });
      }
      const mid: RichTextCharacterStyle =
        JSON.parse(JSON.stringify(run.style)) as RichTextCharacterStyle;
      mid.link = url === null ? undefined : url;
      next.push({ start: Math.max(s, run.start), end: Math.min(e, run.end),
        style: mid });
    }
    if (url !== null) {
      const inside: RichTextCharacterStyleRun[] = next
        .filter((r: RichTextCharacterStyleRun): boolean => r.start < e && r.end > s)
        .sort((a: RichTextCharacterStyleRun, b: RichTextCharacterStyleRun): number =>
          a.start - b.start);
      let pos: number = s;
      for (const run of inside) {
        if (run.start > pos) {
          next.push({ start: pos, end: run.start, style: { link: url } });
        }
        pos = Math.max(pos, run.end);
      }
      if (pos < e) {
        next.push({ start: pos, end: e, style: { link: url } });
      }
    }
    this.draftCharRuns = next;
  }

  // 选区第一个携带 link 的 run 的 url（编辑既有链接时预填，对应 um5→mte）。
  private linkUrlAt(s: number, e: number): string {
    for (const run of this.draftCharRuns) {
      if (run.end > s && run.start < e && run.style.link !== undefined) {
        return run.style.link;
      }
    }
    return '';
  }

  // 原版 tm5→en5 链接对话框：打开时以选中文本/既有链接预填。
  private openLinkSheet(): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    this.linkTitleDraft = s === e ? '' : this.draftText.substring(s, e);
    this.linkUrlDraft = this.linkUrlAt(s, e);
    // 原版 bn5:127：en5.c（既有链接）→ Edit hyperlink，否则 Insert hyperlink。
    this.linkSheetIsEdit = this.linkUrlDraft.length > 0;
    this.showLinkSheet = true;
  }

  // 原版 tte→fm7.l replaceSelectedText：选区（或折叠光标）替换为链接标题
  // 文本并对插入段写 {link:url}；en5.c 语义——标题非空才可确认。
  private confirmLink(): void {
    const url: string = this.linkUrlDraft.trim();
    const title: string = this.linkTitleDraft;
    this.showLinkSheet = false;
    if (url.length === 0 || title.length === 0) {
      return;
    }
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    const previous: string = this.draftText;
    this.draftText = this.draftText.substring(0, s) + title +
      this.draftText.substring(e);
    this.adjustCharRunsForEdit(this.draftText, previous);
    this.applyLinkUrl(url, s, s + title.length);
    this.normalizeCharRuns();
    this.caretOffset = s + title.length;
    this.caretSelectionStart = s + title.length;
    this.linkUrlDraft = '';
    this.linkTitleDraft = '';
    this.refreshCaretCharStyles();
    this.onDraftChange(this.draftText);
  }

  // 原版 aue/wm5→removeHyperlinkFromSelection：清除选区 link 字段。
  private removeLink(): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    this.showLinkSheet = false;
    this.linkUrlDraft = '';
    this.linkTitleDraft = '';
    if (s === e) {
      return;
    }
    this.applyLinkUrl(null, s, e);
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 链接 sheet：URL + Link title 输入 + Add/Remove（受限等价 en5 对话框）。
  @Builder
  private buildLinkSheet(): void {
    Column() {
      Text(this.linkSheetIsEdit ? $r('app.string.edit_hyperlink') :
        $r('app.string.insert_hyperlink'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.element !== null ? this.element.fontColor : '#000000')
        .margin({ bottom: 12 })
      TextInput({ placeholder: $r('app.string.link_url_hint'),
        text: this.linkUrlDraft })
        .type(InputType.Normal)
        .fontSize(14)
        .width('100%')
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.linkUrlDraft = value;
        })
      TextInput({ placeholder: $r('app.string.link_title_hint'),
        text: this.linkTitleDraft })
        .type(InputType.Normal)
        .fontSize(14)
        .width('100%')
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.linkTitleDraft = value;
        })
      Row() {
        Button($r('app.string.add_link'))
          .height(32)
          .fontSize(12)
          .backgroundColor(this.linkUrlDraft.trim().length > 0 &&
            this.linkTitleDraft.length > 0 ?
            this.resolveTokens().accent : this.resolveTokens().surface)
          .fontColor(this.linkUrlDraft.trim().length > 0 &&
            this.linkTitleDraft.length > 0 ?
            this.resolveTokens().onAccent :
            (this.element !== null ? this.element.fontColor : '#000000'))
          .enabled(!this.photoImportLeaseActive &&
            this.linkUrlDraft.trim().length > 0 &&
            this.linkTitleDraft.length > 0)
          .onClick(() => {
            this.confirmLink();
          })
        Button($r('app.string.remove_link'))
          .height(32)
          .fontSize(12)
          .backgroundColor(this.resolveTokens().surface)
          .fontColor(this.element !== null ? this.element.fontColor : '#000000')
          .enabled(!this.photoImportLeaseActive)
          .margin({ left: 8 })
          .onClick(() => {
            this.removeLink();
          })
      }
    }
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
  }

  // 原版 cve kue(superscript→zyd.j)/lue(subscript→zyd.i)：互斥对切换。
  // 启用时同一载荷内显式 FALSE 兄弟字段；停用时只写本字段 FALSE。
  private toggleCharStylePair(field: string, other: string): void {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    if (s === e) {
      if (this.charStyleValue(this.pendingCharStyles, field)) {
        this.charStyleSet(this.pendingCharStyles, field, false);
      } else {
        this.charStyleSet(this.pendingCharStyles, field, true);
        this.charStyleSet(this.pendingCharStyles, other, false);
      }
      this.refreshCaretCharStyles();
      return;
    }
    const on: boolean = !this.rangeHasCharStyle(field, s, e);
    this.applyCharStyle(field, on, s, e);
    if (on) {
      this.applyCharStyle(other, false, s, e);
    }
    this.normalizeCharRuns();
    this.refreshCaretCharStyles();
  }

  // 原版 cve m(new h5a(±1))：光标段落 indentLevel 增减（钳制 >=0），
  // 其余段落字段原样保留；level 归 0 且无其余字段时清除条目保持 canonical。
  private adjustIndentLevel(delta: number): void {
    const paragraphIndex: number = this.paragraphIndexAt(this.caretOffset);
    const current: RichTextParagraphStyle = this.draftStyles.get(paragraphIndex) ?? {};
    const next: RichTextParagraphStyle = {};
    const level: number = Math.max(0, (current.indentLevel ?? 0) + delta);
    if (level > 0) {
      next.indentLevel = level;
    }
    if (current.alignment !== undefined) {
      next.alignment = current.alignment;
    }
    if (current.lineSpacing !== undefined) {
      next.lineSpacing = current.lineSpacing;
    }
    if (current.writingDirection !== undefined) {
      next.writingDirection = current.writingDirection;
    }
    if (current.isChecked !== undefined) {
      next.isChecked = current.isChecked;
    }
    if (current.decoratorStyle !== undefined) {
      next.decoratorStyle = current.decoratorStyle;
    }
    if (current.programmingLanguage !== undefined) {
      next.programmingLanguage = current.programmingLanguage;
    }
    if (Object.keys(next).length === 0) {
      this.draftStyles.delete(paragraphIndex);
    } else {
      this.draftStyles.set(paragraphIndex, next);
    }
  }

  private refreshCaretCodeLanguage(): void {
    const current: RichTextParagraphStyle =
      this.draftStyles.get(this.paragraphIndexAt(this.caretOffset)) ?? {};
    this.caretCodeLanguage = current.programmingLanguage ?? 'plaintext';
  }

  private caretCodeLanguageLabel(): string {
    for (const pair of CODE_LANGUAGES) {
      if (pair[0] === this.caretCodeLanguage) {
        return pair[1];
      }
    }
    return this.caretCodeLanguage;
  }

  private buildCodeLanguageMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    for (const pair of CODE_LANGUAGES) {
      const lang: string = pair[0];
      items.push({ value: pair[1], action: (): void => {
        this.setCodeLanguage(lang);
      } });
    }
    return items;
  }

  // 原版 cve bte→m(new k5a(str))：设置光标段落 programmingLanguage；
  // str===rs1.c.a('plaintext') 时原版映射 null——即清除字段。其余字段
  // 拷贝与 toggleDecoratorStyle 同模式。
  private setCodeLanguage(lang: string): void {
    const paragraphIndex: number = this.paragraphIndexAt(this.caretOffset);
    const current: RichTextParagraphStyle = this.draftStyles.get(paragraphIndex) ?? {};
    const next: RichTextParagraphStyle = {};
    if (current.indentLevel !== undefined) {
      next.indentLevel = current.indentLevel;
    }
    if (current.alignment !== undefined) {
      next.alignment = current.alignment;
    }
    if (current.lineSpacing !== undefined) {
      next.lineSpacing = current.lineSpacing;
    }
    if (current.writingDirection !== undefined) {
      next.writingDirection = current.writingDirection;
    }
    if (current.isChecked !== undefined) {
      next.isChecked = current.isChecked;
    }
    if (current.decoratorStyle !== undefined) {
      next.decoratorStyle = current.decoratorStyle;
    }
    if (lang !== 'plaintext') {
      next.programmingLanguage = lang;
    }
    if (Object.keys(next).length === 0) {
      this.draftStyles.delete(paragraphIndex);
    } else {
      this.draftStyles.set(paragraphIndex, next);
    }
    this.caretCodeLanguage = next.programmingLanguage ?? 'plaintext';
  }

  // 原版 ure.t/qse.P（vse→i5a SetAlignment, r4a LEFT=1/CENTER=2/RIGHT=3）与
  // ure.y/qse.Q（wte→j5a SetLineSpacing, fg7 可选 {1.0,1.5,2.0}）：
  // 段落级字段，随 caret 段落写入 draftStyles；字段拷贝与其他 setter 同模式。
  private refreshCaretParagraphExtras(): void {
    const current: RichTextParagraphStyle =
      this.draftStyles.get(this.paragraphIndexAt(this.caretOffset)) ?? {};
    this.caretAlignment = current.alignment ?? 1;
    this.caretLineSpacing = current.lineSpacing ?? 1;
  }

  private setAlignment(value: number): void {
    const paragraphIndex: number = this.paragraphIndexAt(this.caretOffset);
    const current: RichTextParagraphStyle = this.draftStyles.get(paragraphIndex) ?? {};
    const next: RichTextParagraphStyle = {};
    if (current.indentLevel !== undefined) {
      next.indentLevel = current.indentLevel;
    }
    next.alignment = value;
    if (current.lineSpacing !== undefined) {
      next.lineSpacing = current.lineSpacing;
    }
    if (current.writingDirection !== undefined) {
      next.writingDirection = current.writingDirection;
    }
    if (current.isChecked !== undefined) {
      next.isChecked = current.isChecked;
    }
    if (current.decoratorStyle !== undefined) {
      next.decoratorStyle = current.decoratorStyle;
    }
    if (current.programmingLanguage !== undefined) {
      next.programmingLanguage = current.programmingLanguage;
    }
    this.draftStyles.set(paragraphIndex, next);
    this.caretAlignment = value;
  }

  private setLineSpacing(value: number): void {
    const paragraphIndex: number = this.paragraphIndexAt(this.caretOffset);
    const current: RichTextParagraphStyle = this.draftStyles.get(paragraphIndex) ?? {};
    const next: RichTextParagraphStyle = {};
    if (current.indentLevel !== undefined) {
      next.indentLevel = current.indentLevel;
    }
    if (current.alignment !== undefined) {
      next.alignment = current.alignment;
    }
    next.lineSpacing = value;
    if (current.writingDirection !== undefined) {
      next.writingDirection = current.writingDirection;
    }
    if (current.isChecked !== undefined) {
      next.isChecked = current.isChecked;
    }
    if (current.decoratorStyle !== undefined) {
      next.decoratorStyle = current.decoratorStyle;
    }
    if (current.programmingLanguage !== undefined) {
      next.programmingLanguage = current.programmingLanguage;
    }
    this.draftStyles.set(paragraphIndex, next);
    this.caretLineSpacing = value;
  }

  private buildAlignmentMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    items.push({ value: $r('app.string.align_left'), action: (): void => {
      this.setAlignment(1);
    } });
    items.push({ value: $r('app.string.align_center'), action: (): void => {
      this.setAlignment(2);
    } });
    items.push({ value: $r('app.string.align_right'), action: (): void => {
      this.setAlignment(3);
    } });
    return items;
  }

  private buildLineSpacingMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    const values: number[] = [1.0, 1.5, 2.0];
    for (const value of values) {
      const spacing: number = value;
      items.push({ value: spacing.toFixed(1), action: (): void => {
        this.setLineSpacing(spacing);
      } });
    }
    return items;
  }

  // 原版 h32 工具条按钮语义：段落级 decorator 单选互斥切换（再次点击同项回到 NONE=0）。
  private toggleDecoratorStyle(decorator: number): void {
    const paragraphIndex: number = this.paragraphIndexAt(this.caretOffset);
    const current: RichTextParagraphStyle = this.draftStyles.get(paragraphIndex) ?? {};
    const next: RichTextParagraphStyle = {};
    if (current.indentLevel !== undefined) {
      next.indentLevel = current.indentLevel;
    }
    if (current.alignment !== undefined) {
      next.alignment = current.alignment;
    }
    if (current.lineSpacing !== undefined) {
      next.lineSpacing = current.lineSpacing;
    }
    if (current.writingDirection !== undefined) {
      next.writingDirection = current.writingDirection;
    }
    if (current.isChecked !== undefined) {
      next.isChecked = current.isChecked;
    }
    if (current.decoratorStyle !== decorator) {
      next.decoratorStyle = decorator;
      if (decorator === 5 && current.programmingLanguage !== undefined) {
        next.programmingLanguage = current.programmingLanguage;
      }
    }
    if (Object.keys(next).length === 0) {
      this.draftStyles.delete(paragraphIndex);
    } else {
      this.draftStyles.set(paragraphIndex, next);
    }
    this.caretDecoratorStyle = next.decoratorStyle ?? 0;
    this.refreshCaretCodeLanguage();
  }

  // 原版 fm7.c() clearDecoratorOnCursorParagraph：清光标段 decorator
  // （programmingLanguage 随 code-block 装饰一并清除）。
  private clearParagraphDecorator(paragraphIndex: number): void {
    const current: RichTextParagraphStyle = this.draftStyles.get(paragraphIndex) ?? {};
    const next: RichTextParagraphStyle = {};
    if (current.indentLevel !== undefined) {
      next.indentLevel = current.indentLevel;
    }
    if (current.alignment !== undefined) {
      next.alignment = current.alignment;
    }
    if (current.lineSpacing !== undefined) {
      next.lineSpacing = current.lineSpacing;
    }
    if (current.writingDirection !== undefined) {
      next.writingDirection = current.writingDirection;
    }
    if (current.isChecked !== undefined) {
      next.isChecked = current.isChecked;
    }
    if (Object.keys(next).length === 0) {
      this.draftStyles.delete(paragraphIndex);
    } else {
      this.draftStyles.set(paragraphIndex, next);
    }
    this.caretDecoratorStyle = next.decoratorStyle ?? 0;
    this.refreshCaretCodeLanguage();
  }

  // 段落是否为空段（qi3.c()：内容全为换行——段内除分隔符外零字符）。
  private isParagraphEmpty(offset: number): boolean {
    const start: number = this.draftText.lastIndexOf('\n', offset - 1) + 1;
    let end: number = this.draftText.indexOf('\n', offset);
    if (end < 0) {
      end = this.draftText.length;
    }
    return end === start;
  }

  // 原版 fm7.g（Enter）：空装饰段回车——列表段(1-3)：indent>0 减一级、
  // ==0 清装饰；引用/代码段(4-5)：清装饰；其余放行 '\n' 插入。
  private onWillInsertText(info: InsertValue): boolean {
    if (info.insertValue !== '\n' || this.photoImportLeaseActive) {
      return true;
    }
    const paragraphIndex: number = this.paragraphIndexAt(info.insertOffset);
    const current: RichTextParagraphStyle = this.draftStyles.get(paragraphIndex) ?? {};
    const decorator: number = current.decoratorStyle ?? 0;
    if (!this.isParagraphEmpty(info.insertOffset)) {
      return true;
    }
    if (decorator >= 1 && decorator <= 3) {
      if ((current.indentLevel ?? 0) > 0) {
        this.adjustIndentLevel(-1);
      } else {
        this.clearParagraphDecorator(paragraphIndex);
      }
      return false;
    }
    if (decorator === 4 || decorator === 5) {
      this.clearParagraphDecorator(paragraphIndex);
      return false;
    }
    return true;
  }

  // 原版 fm7.h（Tab）：光标段为列表装饰(1-3) → h5a(+1) 缩进；否则
  // l('\t')=replaceSelectedText 选区替换为制表符。
  private handleTabKey(): boolean {
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    const paragraphIndex: number = this.paragraphIndexAt(this.caretOffset);
    const decorator: number =
      (this.draftStyles.get(paragraphIndex) ?? {}).decoratorStyle ?? 0;
    if (decorator >= 1 && decorator <= 3) {
      this.adjustIndentLevel(1);
      return true;
    }
    const oldText: string = this.draftText;
    this.draftText = oldText.slice(0, s) + '\t' + oldText.slice(e);
    this.adjustCharRunsForEdit(this.draftText, oldText);
    this.controller.caretPosition(s + 1);
    this.onDraftChange(this.draftText);
    return true;
  }

  // 原版 fm7.j→jvi.d：粘贴文本 trim 后若为 URL（URLUtil.isValidUrl ||
  // Patterns.WEB_URL.matches）则规范化——无 scheme 补 https://、
  // http/https 原样、其他 scheme 返回 null；非 URL 走原生粘贴。
  private pastedUrlOrNull(raw: string): string {
    const t: string = raw.trim();
    if (t.length === 0 || /\s/.test(t)) {
      return '';
    }
    const schemeMatch: RegExpMatchArray | null =
      t.match(/^([a-zA-Z][a-zA-Z0-9+.-]*):/);
    if (schemeMatch !== null) {
      const scheme: string = schemeMatch[1].toLowerCase();
      if (scheme !== 'http' && scheme !== 'https') {
        return '';
      }
      return /^https?:\/\/[\w-]+(\.[\w-]+)+(:\d+)?(\/\S*)?$/i.test(t) ? t : '';
    }
    return /^(www\.)?[\w-]+(\.[\w-]+)+(:\d+)?([/?#]\S*)?$/i.test(t) ?
      'https://' + t : '';
  }

  // 原版 fm7.j：URL 粘贴 preventDefault + 选区替换为 trim 后文本并
  // 写 {link:规范化 url}（同 confirmLink 的插入管线）。
  private onTextPaste(value: string, event: PasteEvent): void {
    const url: string = this.pastedUrlOrNull(value);
    if (url.length === 0 || this.photoImportLeaseActive) {
      return;
    }
    if (event.preventDefault !== undefined) {
      event.preventDefault();
    }
    const title: string = value.trim();
    const s: number = Math.max(0, Math.min(this.caretSelectionStart, this.caretOffset));
    const e: number = Math.max(this.caretSelectionStart, this.caretOffset);
    const previous: string = this.draftText;
    this.draftText = this.draftText.substring(0, s) + title +
      this.draftText.substring(e);
    this.adjustCharRunsForEdit(this.draftText, previous);
    this.applyLinkUrl(url, s, s + title.length);
    this.normalizeCharRuns();
    this.caretOffset = s + title.length;
    this.caretSelectionStart = s + title.length;
    this.controller.caretPosition(s + title.length);
    this.refreshCaretCharStyles();
    this.onDraftChange(this.draftText);
  }

  // 提交时把段落序号样式折回字符区间 run（run.end 含段内换行符；末段无换行则止于文末）。
  private computeParagraphRuns(): RichTextParagraphStyleRun[] {
    const runs: RichTextParagraphStyleRun[] = [];
    const text: string = this.draftText;
    let paragraphIndex: number = 0;
    let paragraphStart: number = 0;
    for (let index: number = 0; index <= text.length; index++) {
      if (index === text.length || text.charAt(index) === '\n') {
        const style: RichTextParagraphStyle | undefined = this.draftStyles.get(paragraphIndex);
        if (style !== undefined && Object.keys(style).length > 0) {
          const end: number = index < text.length ? index + 1 : index;
          if (end > paragraphStart) {
            runs.push({ start: paragraphStart, end: end, style: style });
          }
        }
        paragraphStart = index + 1;
        paragraphIndex++;
      }
    }
    return runs;
  }

  // 原版 hke/k09 文本编辑键盘映射（wl6 动作集）：Ctrl+B/I/U 字符样式、
  // Ctrl+A 全选、Ctrl+Home/End 至文首/文末（HOME/END='Go to Start/End
  // of Text'）、Escape/Ctrl+D 取消选区（DESELECT=折叠到 caret）。
  // 差异登记：Ctrl+X/C/V 走 TextArea 原生剪贴板（run 保留=登记缺口）；
  // Ctrl+Z/Y 无草稿级 undo 基建（画布 UndoRedoManager 在提交层）。
  private onEditorKeyEvent(event: KeyEvent): boolean {
    if (event.type !== KeyType.Down || this.photoImportLeaseActive) {
      return false;
    }
    const ctrl: boolean = event.getModifierKeyState !== undefined &&
      (event.getModifierKeyState(['ctrl']) ||
        event.getModifierKeyState(['Ctrl']));
    if (ctrl) {
      if (event.keyCode === 2018) {           // KEYCODE_B
        this.toggleCharStyle('bold');
        return true;
      }
      if (event.keyCode === 2025) {           // KEYCODE_I
        this.toggleCharStyle('italic');
        return true;
      }
      if (event.keyCode === 2037) {           // KEYCODE_U
        this.toggleCharStyle('underline');
        return true;
      }
      if (event.keyCode === 2017) {           // KEYCODE_A = SELECT_ALL
        this.controller.setTextSelection(0, this.draftText.length);
        return true;
      }
      if (event.keyCode === 2081) {           // MOVE_HOME = Go to Start of Text
        this.controller.caretPosition(0);
        return true;
      }
      if (event.keyCode === 2082) {           // MOVE_END = Go to End of Text
        this.controller.caretPosition(this.draftText.length);
        return true;
      }
      if (event.keyCode === 2020) {           // KEYCODE_D = DESELECT
        this.collapseSelection();
        return true;
      }
      return false;
    }
    if (event.keyCode === 2049) {             // KEYCODE_TAB = fm7.h
      return this.handleTabKey();
    }
    if (event.keyCode === 2070) {             // KEYCODE_ESCAPE = DESELECT
      this.collapseSelection();
      return true;
    }
    return false;
  }

  // wl6.DESELECT：选区折叠至 caret 端（caretPosition 折叠语义）。
  private collapseSelection(): void {
    if (this.caretSelectionStart !== this.caretOffset && this.caretOffset >= 0) {
      this.controller.caretPosition(this.caretOffset);
    }
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private transformComponents(): TextBlockTransformComponents {
    return this.element !== null ? textBlockTransformComponents(this.element) : {
      origin: { x: 0, y: 0 }, rotationRadians: 0, scaleX: 1, scaleY: 1,
    };
  }

  private editorWidth(): number {
    if (this.element === null) {
      return 0;
    }
    return this.layoutWidth > 0 ? this.layoutWidth : this.element.blockWidth;
  }

  build() {
    Stack() {
      if (this.editing && this.element !== null) {
        Stack() {
          Stack()
            .width(this.editorWidth() * this.viewportZoom)
            .height(this.element.blockHeight * this.viewportZoom)
            .border({ width: 1.5, color: this.resolveTokens().accent, style: BorderStyle.Dashed })
          TextArea({ text: this.draftText, placeholder: $r('app.string.type_here'),
            controller: this.controller })
            .width(this.editorWidth() * this.viewportZoom)
            .height(this.element.blockHeight * this.viewportZoom)
            .fontSize(this.element.fontSize * this.viewportZoom)
            .lineHeight((this.element.fontSize + 8) * this.viewportZoom)
            .fontColor(this.element.fontColor)
            .backgroundColor(this.resolveTokens().surface)
            .padding({
              left: this.element.contentLeftInset * this.viewportZoom,
              top: this.element.contentTopInset * this.viewportZoom,
              right: (this.element.contentRightInset ?? this.element.contentLeftInset) *
                this.viewportZoom,
              bottom: (this.element.contentBottomInset ?? this.element.contentTopInset) *
                this.viewportZoom,
            })
            .enabled(!this.photoImportLeaseActive)
            .onAppear(() => {
              if (this.restoreCaret >= 0) {
                this.controller.caretPosition(Math.min(this.restoreCaret, this.draftText.length));
              }
            })
            .onKeyEvent((event: KeyEvent): boolean => {
              return this.onEditorKeyEvent(event);
            })
            .onWillInsert((info: InsertValue): boolean => {
              return this.onWillInsertText(info);
            })
            .onPaste((value: string, event: PasteEvent): void => {
              this.onTextPaste(value, event);
            })
            .onTextSelectionChange((start: number, end: number) => {
              this.caretOffset = end;
              this.caretSelectionStart = start;
              this.caretDecoratorStyle = this.decoratorAt(end);
              this.refreshCaretCodeLanguage();
              this.refreshCaretCharStyles();
              this.onCaretChange(end);
            })
            .onChange((value: string) => {
              if (this.photoImportLeaseActive) {
                return;
              }
              const previous: string = this.draftText;
              this.draftText = value;
              const editStart: number = this.adjustCharRunsForEdit(value, previous);
              const delta: number = value.length - previous.length;
              if (delta > 0 && Object.keys(this.pendingCharStyles).length > 0) {
                const insEnd: number = editStart + delta;
                const fields: string[] =
                  ['bold', 'italic', 'underline', 'strikethrough',
                    'subscript', 'superscript'];
                for (const field of fields) {
                  if (this.charStyleHas(this.pendingCharStyles, field)) {
                    this.applyCharStyle(field,
                      this.charStyleValue(this.pendingCharStyles, field),
                      editStart, insEnd);
                  }
                }
                if (this.pendingClearHighlight) {
                  this.applyHighlightColor(null, editStart, insEnd);
                } else if (this.pendingCharStyles.highlightColor !== undefined) {
                  this.applyHighlightColor(this.pendingCharStyles.highlightColor,
                    editStart, insEnd);
                }
                if (this.pendingCharStyles.fontSize !== undefined) {
                  this.applyFontSize(this.pendingCharStyles.fontSize,
                    editStart, insEnd);
                }
                if (this.pendingClearForeground) {
                  this.applyForegroundColor(null, editStart, insEnd);
                } else if (this.pendingCharStyles.foregroundColor !== undefined) {
                  this.applyForegroundColor(this.pendingCharStyles.foregroundColor,
                    editStart, insEnd);
                }
                if (this.pendingClearFamily) {
                  this.applyFontFamily(null, editStart, insEnd);
                } else if (this.pendingCharStyles.familyName !== undefined) {
                  this.applyFontFamily(this.pendingCharStyles.familyName,
                    editStart, insEnd);
                }
                this.normalizeCharRuns();
              }
              this.onDraftChange(value);
            })
        }
          .width(this.editorWidth() * this.viewportZoom)
          .height(this.element.blockHeight * this.viewportZoom)
          .position({ x: this.screenOrigin.x, y: this.screenOrigin.y })
          .scale({
            x: this.transformComponents().scaleX,
            y: this.transformComponents().scaleY,
            centerX: 0,
            centerY: 0,
          })
          .rotate({
            x: 0,
            y: 0,
            z: 1,
            angle: this.transformComponents().rotationRadians.toString() + 'rad',
            centerX: 0,
            centerY: 0,
          })
        Row() {
          // 原版 i31 字体样式面板 / cve ote→hr4 预设：zyd{bold,italic:false,
          // fontSize} 原子写选区（折叠光标写 pending）。
          Button($r('app.string.text_style'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.resolveTokens().surface)
            .fontColor(this.element !== null ? this.element.fontColor : '#000000')
            .enabled(!this.photoImportLeaseActive)
            .bindMenu(this.buildTextStyleMenu())
          // 原版 kre FontSizeTextToolbarItem：字号显示 + ±1pt 步进
          // （pte→cve.l(f)→zyd.f clamp [4,72]）。
          Button('-')
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.stepFontSize(-1);
            })
          Text(`${this.caretCharFontSize}`)
            .fontSize(12)
            .fontColor(this.element !== null ? this.element.fontColor : '#000000')
            .margin({ left: 4 })
          Button('+')
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.stepFontSize(1);
            })
          // 原版 i31 字体族区 / cve nte→zyd.e：qr4 三随包字体 + Default。
          Button($r('app.string.font_family'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.resolveTokens().surface)
            .fontColor(this.element !== null ? this.element.fontColor : '#000000')
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .bindMenu(this.buildFontMenu())
          // 原版 h32/l32 文本格式行的字符样式项：bold/italic/underline/
          // strikethrough（l32 渲染；cve 经 i5a/j5a/zyd 字符样式变更派单）。
          // 选区非空时改写选区 run；折叠光标时翻 pending typing-attributes。
          Button($r('app.string.bold'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretCharBold ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretCharBold ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .onClick(() => {
              this.toggleCharStyle('bold');
            })
          Button($r('app.string.increase_indent'))
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.adjustIndentLevel(1);
            })
          Button($r('app.string.decrease_indent'))
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.adjustIndentLevel(-1);
            })
          Button($r('app.string.italic'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretCharItalic ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretCharItalic ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleCharStyle('italic');
            })
          Button($r('app.string.underline'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretCharUnderline ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretCharUnderline ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleCharStyle('underline');
            })
          Button($r('app.string.subscript'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretCharSub ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretCharSub ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleCharStylePair('subscript', 'superscript');
            })
          Button($r('app.string.superscript'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretCharSuper ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretCharSuper ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleCharStylePair('superscript', 'subscript');
            })
          Button($r('app.string.strikethrough'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretCharStrike ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretCharStrike ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleCharStyle('strikethrough');
            })
          // 原版 rte 高亮：菜单选择色=应用（eh5{iu1,true}），Remove=清除。
          Button($r('app.string.text_highlight'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretCharHighlight ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretCharHighlight ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .bindMenu(this.buildHighlightMenu())
          // 原版 i31 文字色井（qse.O）/ qte→zyd.g：色板 sheet 选色写
          // foregroundColor run；Automatic 恢复 element.fontColor。
          Button($r('app.string.text_color'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.resolveTokens().surface)
            .fontColor(this.element !== null ? this.element.fontColor : '#000000')
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .bindSheet(this.showTextColorSheet, this.buildTextColorSheet(), {
              height: SheetSize.MEDIUM,
              showClose: true,
            })
            .onClick(() => {
              this.hsvTarget = 0;
              this.showTextColorSheet = true;
            })
          // 原版 tqe.LINK/tte/aue：链接 sheet（URL+标题）→ replaceSelectedText
          // + zyd.h；Remove Link 清选区 link 字段。
          Button($r('app.string.text_link'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.resolveTokens().surface)
            .fontColor(this.element !== null ? this.element.fontColor : '#000000')
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .bindSheet(this.showHsvSheet, this.buildHsvSheet(), {
              height: SheetSize.MEDIUM,
              showClose: true,
            })
            .bindSheet(this.showLinkSheet, this.buildLinkSheet(), {
              height: SheetSize.MEDIUM,
              showClose: true,
            })
            .onClick(() => {
              this.openLinkSheet();
            })
          // 原版 h32/l32 文本格式行的段落装饰项：BULLET/NUMBER/CHECK_BOX/
          // BLOCK_QUOTE/CODE_BLOCK（fy2 1~5，cve.o(fy2) 单选互斥）。
          // link/indent 后续期补齐。
          Button($r('app.string.bullet_list'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretDecoratorStyle === 1 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretDecoratorStyle === 1 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .onClick(() => {
              this.toggleDecoratorStyle(1);
            })
          Button($r('app.string.numbered_list'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretDecoratorStyle === 2 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretDecoratorStyle === 2 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleDecoratorStyle(2);
            })
          Button($r('app.string.checkbox_list'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretDecoratorStyle === 3 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretDecoratorStyle === 3 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleDecoratorStyle(3);
            })
          Button($r('app.string.block_quote'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretDecoratorStyle === 4 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretDecoratorStyle === 4 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleDecoratorStyle(4);
            })
          Button($r('app.string.code_block'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretDecoratorStyle === 5 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretDecoratorStyle === 5 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleDecoratorStyle(5);
            })
          // 原版 bte 语言选择项：仅光标段落为 CODE_BLOCK 时出现；
          // 按钮显示当前语言，点击弹 rs1.d 27 项菜单。
          if (this.caretDecoratorStyle === 5) {
            Button(this.caretCodeLanguageLabel())
              .height(32)
              .fontSize(12)
              .enabled(!this.photoImportLeaseActive)
              .margin({ left: 4 })
              // 原版 i8j→koi.a：语言菜单带 programming_language 标题。
              .bindMenu(this.buildCodeLanguageMenu(),
                { title: $r('app.string.programming_language') })
          }
          // 原版 ure.t→qse.P 对齐面板（vse(r4a)→i5a）：左/中/右三档。
          Button($r('app.string.text_alignment'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretAlignment !== 1 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretAlignment !== 1 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .bindMenu(this.buildAlignmentMenu())
          // 原版 ure.y→qse.Q 行距面板（wte(f)→j5a）：fg7 预设 {1.0,1.5,2.0}。
          Button($r('app.string.line_spacing'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretLineSpacing !== 1 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretLineSpacing !== 1 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .bindMenu(this.buildLineSpacingMenu())
          Button($r('app.string.done'))
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(async () => {
              if (this.photoImportLeaseActive) {
                return;
              }
              if (await this.onCommit(this.draftText, this.draftCharRuns,
                this.computeParagraphRuns())) {
                this.draftText = '';
                this.draftStyles.clear();
                this.draftCharRuns = [];
                this.pendingCharStyles = {};
                this.pendingClearHighlight = false;
                this.pendingClearForeground = false;
                this.pendingClearFamily = false;
              }
            })
          Button($r('app.string.cancel'))
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.draftText = '';
              this.onCancel();
            })
        }
        .position({
          x: this.screenBounds.left,
          y: this.screenBounds.bottom + 4,
        })
      }
    }
    // 固定左上角 + 零尺寸：position 子组件按实际位置参与 hit，不遮挡下层 Canvas
    .position({ x: 0, y: 0 })
    .width(0)
    .height(0)
  }
}
