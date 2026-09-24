// T-024 文本框编辑覆盖层（TextArea 编辑态）
import { RichTextCharacterStyle, RichTextCharacterStyleRun, TextBlockElement, RichTextParagraphStyle, RichTextParagraphStyleRun } from '../../core/model/ElementTypes';
import { Point2D, Rect2D } from '../../core/model/GeometryTypes';
import { textBlockTransformComponents, TextBlockTransformComponents } from '../../core/model/TextBlockGeometry';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

// 原版 rs1.d 代码块语言表（27 项，含 plaintext 哨兵 rs1.c——原版派单把
// plaintext 映射为 null=清除 programmingLanguage 字段）。
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
  // 原版 rte/eh5：高亮态（选区全覆盖或 pending 含色）。
  @State caretCharHighlight: boolean = false;
  private pendingClearHighlight: boolean = false;
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
    this.draftText = this.element !== null ? this.element.richText : '';
    this.seedParagraphStyles();
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
      return;
    }
    this.caretCharBold = this.rangeHasCharStyle('bold', s, e);
    this.caretCharItalic = this.rangeHasCharStyle('italic', s, e);
    this.caretCharUnderline = this.rangeHasCharStyle('underline', s, e);
    this.caretCharStrike = this.rangeHasCharStyle('strikethrough', s, e);
    this.caretCharSub = this.rangeHasCharStyle('subscript', s, e);
    this.caretCharSuper = this.rangeHasCharStyle('superscript', s, e);
    this.caretCharHighlight = this.rangeHasHighlight(s, e);
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
    items.push({ value: $r('app.string.highlight_remove'),
      action: (): void => {
        this.clearHighlight();
      } });
    return items;
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
              .bindMenu(this.buildCodeLanguageMenu())
          }
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
