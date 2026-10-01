// 原版 1.4.2 io.noties.prism4j（Prism4j）语法高亮引擎移植：
//   ehd.java   = Prism4j 分词引擎（matchGrammar/tokenize + grammar(name) 分发）
//   mnc.java   = Prism4j.Pattern（regex/lookbehind/greedy/alias/inside）
//   zmi.java   = Prism4j.Token（name + patterns）
//   zm6/chd    = GrammarImpl/Grammar
//   s3i.java   = TextImpl 文本节点 / znh.java = SyntaxImpl 记号节点
//   rgm.java   = GrammarUtils（extend/insertBefore/findToken/insideOf）
//   c9n.b/c    = 语法深拷贝（identity 表防环）
//   ynh.java   = token 名→bni 类目映射 + 递归 span 提取
//   o3i.b      = bni 类目 → uog 文字色（GitHub-light 系调色板）
//   vza.java   = 语言别名解析 + 支持集（15 内建语法 + 11 惰性语法 = 26）
// 原版 o3i.c：CODE_BLOCK 段落按 programmingLanguage 分词取 span，
// 仅布局/渲染期覆盖字符颜色（uog 只设 color），不改持久化样式 run —— 移植同此。

/** 一条着色 span：[start, end) 覆盖 color（ARGB u32）。 */
export interface CodeStyleSpan {
  start: number;
  end: number;
  color: number;
}

// ---------- 节点模型（s3i / znh / dhd） ----------
class CodeTextNode {
  literal: string = '';
}

class CodeSyntaxNode {
  type: string = '';               // znh.a：token 名
  children: CodeNode[] = [];       // znh.b
  alias: string | null = null;     // znh.c
  matchedString: string = '';      // znh.d
  greedy: boolean = false;         // znh.e：来源 pattern 的 greedy 标记
  tokenized: boolean = false;      // znh.f：children 是否经 inside 语法再分词
}

type CodeNode = CodeTextNode | CodeSyntaxNode;

function isSyntaxNode(node: CodeNode): boolean {
  return node instanceof CodeSyntaxNode;
}

function isGreedyNode(node: CodeNode | undefined): boolean {
  return node instanceof CodeSyntaxNode && node.greedy;
}

function nodeLength(node: CodeNode): number {
  return node instanceof CodeSyntaxNode ? node.matchedString.length : node.literal.length;
}

// ---------- 语法模型（mnc / zmi / zm6） ----------
class CodePattern {
  regex: RegExp;
  lookbehind: boolean;             // mnc.b：捕获组 1 作 lookbehind
  greedy: boolean;                 // mnc.c：允许跨已有节点贪心扩展
  alias: string | null;
  inside: CodeGrammar | null;      // mnc.e：匹配文本再按 inside 语法分词

  constructor(regex: RegExp, lookbehind: boolean, greedy: boolean,
    alias: string | null, inside: CodeGrammar | null) {
    this.regex = regex;
    this.lookbehind = lookbehind;
    this.greedy = greedy;
    this.alias = alias;
    this.inside = inside;
  }
}

class CodeTokenRule {
  name: string;
  patterns: CodePattern[];

  constructor(name: string, patterns: CodePattern[]) {
    this.name = name;
    this.patterns = patterns;
  }
}

class CodeGrammar {
  name: string;
  tokens: CodeTokenRule[];         // 可变列表：insertBefore/追加直接改写

  constructor(name: string, tokens: CodeTokenRule[]) {
    this.name = name;
    this.tokens = tokens;
  }
}

// ---------- pattern/token/grammar 构造辅助（ehd.d/e/f/g/h/a） ----------
function pat(regex: RegExp): CodePattern {                        // ehd.d
  return new CodePattern(regex, false, false, null, null);
}

function patGreedy(regex: RegExp, lookbehind: boolean): CodePattern { // ehd.e
  return new CodePattern(regex, lookbehind, true, null, null);
}

function patFlag(regex: RegExp, lookbehind: boolean, greedy: boolean,
  alias: string | null): CodePattern {                            // ehd.f
  return new CodePattern(regex, lookbehind, greedy, alias, null);
}

function patLook(regex: RegExp): CodePattern {                    // ehd.g
  return new CodePattern(regex, true, false, null, null);
}

function patInside(regex: RegExp, lookbehind: boolean, greedy: boolean,
  alias: string | null, inside: CodeGrammar | null): CodePattern { // 全参 mnc
  return new CodePattern(regex, lookbehind, greedy, alias, inside);
}

function tok(name: string, ...patterns: CodePattern[]): CodeTokenRule { // ehd.h
  return new CodeTokenRule(name, patterns);
}

function gram(name: string, ...tokens: CodeTokenRule[]): CodeGrammar {  // ehd.a
  return new CodeGrammar(name, tokens);
}

// ---------- 分词引擎（ehd.c = Prism4j.matchGrammar） ----------
// JS 移植差异：Java Matcher.region(position,len) 用 text.substring(position)
// 等价（^ 锚定区域起点语义一致）；\b 在区域起点失去前置字符上下文（差异见 ADR）。
function matchCodeGrammar(text: string, entries: CodeNode[], grammar: CodeGrammar,
  index: number, startPosition: number, oneShot: boolean,
  target: CodeTokenRule | null): void {
  const textLength: number = text.length;
  for (const rule of grammar.tokens) {
    if (rule === target) {
      return;
    }
    for (const pattern of rule.patterns) {
      const lookbehind: boolean = pattern.lookbehind;
      const greedy: boolean = pattern.greedy;
      const regex: RegExp = pattern.regex;
      let i: number = index;
      let position: number = startPosition;
      while (i < entries.length) {
        if (entries.length > textLength) {
          throw new Error('prism4j internal error: nodes > text length');
        }
        const node: CodeNode = entries[i];
        if (isSyntaxNode(node)) {
          position += nodeLength(node);
          i++;
          continue;
        }
        let str: string = (node as CodeTextNode).literal;
        let match: RegExpExecArray | null = null;
        let deleteCount: number = 1;
        let greedyMatch: boolean = false;
        let greedyAdd: number = 0;
        let regionStart: number = position;
        if (greedy && i !== entries.length - 1) {
          const sub: string = text.substring(position);
          match = regex.exec(sub);
          if (!match) {
            break;
          }
          let from: number = match.index + position;
          if (lookbehind && match[1] !== undefined) {
            from += match[1].length;
          }
          const to: number = match.index + position + match[0].length;
          let k: number = i;
          let p: number = position;
          while (k < entries.length &&
            (p < to || (!isSyntaxNode(entries[k]) &&
              (k === 0 || !isGreedyNode(entries[k - 1]))))) {
            p += nodeLength(entries[k]);
            if (from >= p) {
              i += 1;
              position = p;
            }
            k++;
          }
          if (isSyntaxNode(entries[i])) {
            position += nodeLength(entries[i]);
            i++;
            continue;
          }
          deleteCount = k - i;
          str = text.substring(position, p);
          greedyMatch = true;
          greedyAdd = -position;
        } else {
          match = regex.exec(str);
        }
        if (!greedyMatch && !match) {
          if (oneShot) {
            break;
          }
          position += nodeLength(entries[i]);
          i++;
          continue;
        }
        let lookbehindLength: number = 0;
        if (lookbehind && match !== null && match[1] !== undefined) {
          lookbehindLength = match[1].length;
        }
        const matched: RegExpExecArray = match as RegExpExecArray;
        const matchedIndex: number = greedyMatch ? matched.index + regionStart : matched.index;
        const from2: number = matchedIndex + greedyAdd + lookbehindLength;
        const matchedText: string = lookbehindLength > 0 ?
          matched[0].substring(lookbehindLength) : matched[0];
        const to2: number = from2 + matchedText.length;
        for (let d = 0; d < deleteCount; d++) {
          entries.splice(i, 1);
        }
        let i2: number = i;
        if (from2 !== 0) {
          const before: string = str.substring(0, from2);
          i += 1;
          position += before.length;
          const textNode: CodeTextNode = new CodeTextNode();
          textNode.literal = before;
          entries.splice(i2, 0, textNode);
          i2 += 1;
        }
        const inside: CodeGrammar | null = pattern.inside;
        const hasInside: boolean = inside !== null;
        const tokenEntries: CodeNode[] = hasInside ?
          tokenizeCode(matchedText, inside as CodeGrammar) : [textNodeOf(matchedText)];
        const syntax: CodeSyntaxNode = new CodeSyntaxNode();
        syntax.type = rule.name;
        syntax.children = tokenEntries;
        syntax.alias = pattern.alias;
        syntax.matchedString = matchedText;
        syntax.greedy = greedy;
        syntax.tokenized = hasInside;
        entries.splice(i2, 0, syntax);
        i2 += 1;
        if (to2 < str.length) {
          const after: CodeTextNode = new CodeTextNode();
          after.literal = str.substring(to2);
          entries.splice(i2, 0, after);
        }
        if (deleteCount !== 1) {
          matchCodeGrammar(text, entries, grammar, i, position, true, rule);
        }
        if (oneShot) {
          break;
        }
        position += nodeLength(entries[i]);
        i++;
      }
    }
  }
}

function textNodeOf(literal: string): CodeTextNode {
  const node: CodeTextNode = new CodeTextNode();
  node.literal = literal;
  return node;
}

// ehd.i = Prism4j.tokenize
function tokenizeCode(text: string, grammar: CodeGrammar): CodeNode[] {
  const entries: CodeNode[] = [textNodeOf(text)];
  matchCodeGrammar(text, entries, grammar, 0, 0, false, null);
  return entries;
}

// ---------- 深拷贝（c9n.b/c：identity 表防环） ----------
function cloneTokenRule(rule: CodeTokenRule,
  seen: Map<object, object>): CodeTokenRule {
  const hit: object | undefined = seen.get(rule);
  if (hit !== undefined) {
    return hit as CodeTokenRule;
  }
  const clone: CodeTokenRule = new CodeTokenRule(rule.name, []);
  seen.set(rule, clone);
  for (const pattern of rule.patterns) {
    const cached: object | undefined = seen.get(pattern);
    if (cached !== undefined) {
      clone.patterns.push(cached as CodePattern);
      continue;
    }
    const inside: CodeGrammar | null = pattern.inside;
    const patternClone: CodePattern = new CodePattern(pattern.regex,
      pattern.lookbehind, pattern.greedy, pattern.alias,
      inside !== null ? cloneCodeGrammar(inside, seen) : null);
    seen.set(pattern, patternClone);
    clone.patterns.push(patternClone);
  }
  return clone;
}

function cloneCodeGrammar(grammar: CodeGrammar,
  seen: Map<object, object>): CodeGrammar {
  const hit: object | undefined = seen.get(grammar);
  if (hit !== undefined) {
    return hit as CodeGrammar;
  }
  const clone: CodeGrammar = new CodeGrammar(grammar.name, []);
  seen.set(grammar, clone);
  for (const rule of grammar.tokens) {
    clone.tokens.push(cloneTokenRule(rule, seen));
  }
  return clone;
}

// ---------- 语法工具（rgm.c/d/e/f/g/h） ----------
// rgm.i：取语法（不含在本模块内联调度）
// rgm.d：extend——深拷贝基语法，同名 token 原位替换
function extendCodeGrammar(base: CodeGrammar, name: string,
  ...replacements: CodeTokenRule[]): CodeGrammar {
  const map: Map<string, CodeTokenRule> = new Map();
  for (const rule of replacements) {
    map.set(rule.name, rule);
  }
  const seen: Map<object, object> = new Map();
  const tokens: CodeTokenRule[] = [];
  for (const rule of base.tokens) {
    const swap: CodeTokenRule | undefined = map.get(rule.name);
    tokens.push(swap !== undefined ? swap : cloneTokenRule(rule, seen));
  }
  return new CodeGrammar(name, tokens);
}

// rgm.c：extend + 谓词过滤（如 C 丢 class-name/boolean、Kotlin/Go 丢 class-name）
function extendCodeGrammarFiltered(base: CodeGrammar, name: string,
  keep: (rule: CodeTokenRule) => boolean,
  ...replacements: CodeTokenRule[]): CodeGrammar {
  const map: Map<string, CodeTokenRule> = new Map();
  for (const rule of replacements) {
    map.set(rule.name, rule);
  }
  const seen: Map<object, object> = new Map();
  const tokens: CodeTokenRule[] = [];
  for (const rule of base.tokens) {
    if (!keep(rule)) {
      continue;
    }
    const swap: CodeTokenRule | undefined = map.get(rule.name);
    tokens.push(swap !== undefined ? swap : cloneTokenRule(rule, seen));
  }
  return new CodeGrammar(name, tokens);
}

// rgm.e：token 首个 pattern 的 inside 语法
function tokenInside(rule: CodeTokenRule): CodeGrammar | null {
  for (const pattern of rule.patterns) {
    if (pattern.inside !== null) {
      return pattern.inside;
    }
  }
  return null;
}

// rgm.f：按 "a.b.c" 路径下钻 inside 语法找 token
function findCodeToken(grammar: CodeGrammar, path: string[]): CodeTokenRule | null {
  const name: string = path[0];
  const last: boolean = path.length === 1;
  for (const rule of grammar.tokens) {
    if (rule.name !== name) {
      continue;
    }
    if (last) {
      return rule;
    }
    const inside: CodeGrammar | null = tokenInside(rule);
    if (inside !== null) {
      return findCodeToken(inside, path.slice(1));
    }
    return null;
  }
  return null;
}

// rgm.g/h：在指定路径 token 前插入新 token
function insertBeforeCodeToken(grammar: CodeGrammar, path: string,
  ...tokens: CodeTokenRule[]): void {
  if (tokens.length === 0) {
    return;
  }
  insertBeforeAtPath(grammar, path.split('.'), tokens);
}

function insertBeforeAtPath(grammar: CodeGrammar, path: string[],
  tokens: CodeTokenRule[]): void {
  const name: string = path[0];
  const last: boolean = path.length === 1;
  for (let i = 0; i < grammar.tokens.length; i++) {
    const rule: CodeTokenRule = grammar.tokens[i];
    if (rule.name !== name) {
      continue;
    }
    if (last) {
      grammar.tokens.splice(i, 0, ...tokens);
      return;
    }
    const inside: CodeGrammar | null = tokenInside(rule);
    if (inside !== null) {
      insertBeforeAtPath(inside, path.slice(1), tokens);
    }
    return;
  }
}

// ---------- token 类目映射（ynh.f：token 名 → bni 类目） ----------
const TOKEN_CATEGORY: Map<string, string> = new Map<string, string>([
  ['keyword', 'KEYWORD'], ['keyword-control', 'KEYWORD'],
  ['keyword-operator', 'KEYWORD'], ['important', 'KEYWORD'], ['atrule', 'KEYWORD'],
  ['string', 'STRING'], ['char', 'STRING'], ['triple-quoted-string', 'STRING'],
  ['attr-value', 'STRING'],
  ['string-escape', 'STRING_ESCAPE'],
  ['comment', 'COMMENT'], ['prolog', 'COMMENT'], ['doctype', 'COMMENT'],
  ['cdata', 'COMMENT'],
  ['function', 'FUNCTION'], ['function-name', 'FUNCTION'],
  ['function-variable', 'FUNCTION'], ['method-name', 'FUNCTION'],
  ['class-name', 'CLASS_NAME'],
  ['number', 'NUMBER'],
  ['boolean', 'CONSTANT'], ['constant', 'CONSTANT'], ['symbol', 'CONSTANT'],
  ['null', 'CONSTANT'], ['undefined', 'CONSTANT'], ['url', 'CONSTANT'],
  ['entity', 'CONSTANT'],
  ['operator', 'OPERATOR'],
  ['punctuation', 'PUNCTUATION'],
  ['property', 'PROPERTY'], ['property-access', 'PROPERTY'],
  ['attr-name', 'PROPERTY'],
  ['tag', 'TAG'], ['selector', 'TAG'], ['namespace', 'TAG'],
  ['regex', 'REGEX'],
  ['variable', 'VARIABLE'], ['parameter', 'VARIABLE'],
  ['builtin', 'BUILTIN'], ['builtin-class', 'BUILTIN'],
  ['builtin-function', 'BUILTIN'],
  ['decorator', 'DECORATOR'], ['annotation', 'DECORATOR'],
]);

// ---------- 类目调色板（o3i.b：bni 序号 → ARGB；GitHub-light 系） ----------
const CATEGORY_COLORS: Map<string, number> = new Map<string, number>([
  ['KEYWORD', 0xFFD73A49],     // case 0 默认 j
  ['STRING', 0xFF032F62],      // case 1
  ['STRING_ESCAPE', 0xFF005CC5], // case 2
  ['COMMENT', 0xFF6A737D],     // case 3
  ['FUNCTION', 0xFF6F42C1],    // case 4
  ['CLASS_NAME', 0xFFE36209],  // case 5
  ['NUMBER', 0xFF005CC5],      // case 6
  ['CONSTANT', 0xFF005CC5],    // case 7
  ['OPERATOR', 0xFFD73A49],    // case 8 默认 j
  ['PUNCTUATION', 0xFF24292E], // case 9
  ['PROPERTY', 0xFFE36209],    // case 10
  ['TAG', 0xFF22863A],         // case 11
  ['REGEX', 0xFF032F62],       // case 12
  ['VARIABLE', 0xFFE36209],    // case 13
  ['BUILTIN', 0xFF005CC5],     // case 14
  ['DECORATOR', 0xFF6F42C1],   // case 15
]);

// ynh.a：递归展开 token 树→span。token 类目 = 名字→类目 ?? alias→类目
// ?? 父级类目（继承）；有 children 时递归（children 文本和 = matchedString，
// 位置已被递归消费，故不再二次累加——原版此处同义）。
function collectCodeSpans(nodes: CodeNode[], position: number,
  parentCategory: string | null, out: CodeStyleSpan[]): number {
  for (const node of nodes) {
    const length: number = nodeLength(node);
    if (node instanceof CodeSyntaxNode) {
      let category: string | null | undefined = TOKEN_CATEGORY.get(node.type);
      if (category === undefined && node.alias !== null && node.alias.length > 0) {
        category = TOKEN_CATEGORY.get(node.alias);
      }
      if (category === undefined) {
        category = parentCategory;
      }
      if (node.children.length > 0) {
        position = collectCodeSpans(node.children, position, category ?? null, out);
        continue;
      }
      if (category !== undefined && category !== null) {
        const color: number | undefined = CATEGORY_COLORS.get(category);
        if (color !== undefined) {
          out.push({ start: position, end: position + length, color: color });
        }
      }
    } else if (parentCategory !== null) {
      const color: number | undefined = CATEGORY_COLORS.get(parentCategory);
      if (color !== undefined) {
        out.push({ start: position, end: position + length, color: color });
      }
    }
    position += length;
  }
  return position;
}

// ---------- 语言注册表（vza.h 别名 + vza.H 支持集 + ehd.b 惰性构建缓存） ----------
const CODE_LANG_ALIASES: Map<string, string> = new Map<string, string>([
  ['typescript', 'javascript'], ['shell', 'bash'], ['sh', 'bash'],
  ['rs', 'rust'], ['rb', 'ruby'], ['hs', 'haskell'], ['objc', 'objectivec'],
  ['dotnet', 'csharp'], ['mathml', 'markup'], ['svg', 'markup'],
  ['xml', 'markup'], ['html', 'markup'], ['js', 'javascript'], ['jsonp', 'json'],
]);

// vza.H：15 个内建语法名 + vza.I 惰性语法名（Phase 1398 注册后者创建器）。
const SUPPORTED_CODE_LANGS: Set<string> = new Set<string>([
  'c', 'clike', 'cpp', 'csharp', 'css', 'go', 'java', 'javascript', 'json',
  'kotlin', 'markdown', 'markup', 'python', 'sql', 'swift',
  'bash', 'haskell', 'lua', 'matlab', 'objectivec', 'ocaml', 'php', 'r',
  'racket', 'ruby', 'rust',
]);

// ehd.b 的 map：构建结果缓存；null 哨兵对应原版 wzaVar（构建失败标记）。
const grammarCache: Map<string, CodeGrammar | null> = new Map();

type GrammarCreator = () => CodeGrammar | null;

const CODE_GRAMMAR_CREATORS: Map<string, GrammarCreator> = new Map();

function registerCoreGrammars(): void {
  CODE_GRAMMAR_CREATORS.set('clike', grammarClike);
  CODE_GRAMMAR_CREATORS.set('csharp', grammarCsharp);
  CODE_GRAMMAR_CREATORS.set('kotlin', grammarKotlin);
  CODE_GRAMMAR_CREATORS.set('markup', grammarMarkup);
  CODE_GRAMMAR_CREATORS.set('python', grammarPython);
  CODE_GRAMMAR_CREATORS.set('c', grammarC);
  CODE_GRAMMAR_CREATORS.set('go', grammarGo);
  CODE_GRAMMAR_CREATORS.set('cpp', grammarCpp);
  CODE_GRAMMAR_CREATORS.set('css', grammarCss);
  CODE_GRAMMAR_CREATORS.set('sql', grammarSql);
  CODE_GRAMMAR_CREATORS.set('java', grammarJava);
  CODE_GRAMMAR_CREATORS.set('json', grammarJson);
  CODE_GRAMMAR_CREATORS.set('swift', grammarSwift);
  CODE_GRAMMAR_CREATORS.set('javascript', grammarJavascript);
  CODE_GRAMMAR_CREATORS.set('markdown', grammarMarkdown);
}

// ehd.b：别名归一 → 缓存 → 惰性构建（markup 构建后热切 javascript/css 完成
// script/style 互注——原版 b() 尾部 str7.equals("markup") 分支同义）。
function codeGrammar(name: string): CodeGrammar | null {
  const canonical: string = CODE_LANG_ALIASES.get(name) ?? name;
  if (grammarCache.has(canonical)) {
    return grammarCache.get(canonical) ?? null;
  }
  if (!SUPPORTED_CODE_LANGS.has(canonical)) {
    return null;
  }
  const creator: GrammarCreator | undefined = CODE_GRAMMAR_CREATORS.get(canonical);
  const grammar: CodeGrammar | null = creator !== undefined ? creator() : null;
  grammarCache.set(canonical, grammar);
  if (grammar !== null && canonical === 'markup') {
    codeGrammar('javascript');
    codeGrammar('css');
  }
  return grammar;
}

/**
 * 原版 o3i.c/ynh：CODE_BLOCK 段落文本按语言分词并产出颜色 span。
 * 语言不支持/语法缺失/分词异常时返回空 span（原版 list2 = em4.F 同义）。
 */
export function codeBlockHighlightSpans(text: string,
  language: string): CodeStyleSpan[] {
  const spans: CodeStyleSpan[] = [];
  if (text.length === 0) {
    return spans;
  }
  const canonical: string = CODE_LANG_ALIASES.get(language) ?? language;
  if (!SUPPORTED_CODE_LANGS.has(canonical)) {
    return spans;
  }
  const grammar: CodeGrammar | null = codeGrammar(canonical);
  if (grammar === null) {
    return spans;
  }
  let nodes: CodeNode[];
  try {
    nodes = tokenizeCode(text, grammar);
  } catch (e) {
    return spans;
  }
  collectCodeSpans(nodes, 0, null, spans);
  return spans;
}

// ---------- 语法定义（ehd.b 分派体：15 个内建语法） ----------
// 记号与原版一致：pat=ehd.d 普通；patGreedy=ehd.e(lookbehind+greedy)；
// patFlag=ehd.f(lookbehind/greedy/alias)；patLook=ehd.g(lookbehind)；
// patInside=全参 mnc；tok=ehd.h；gram=ehd.a。
// Java Pattern flags：2=CASE_INSENSITIVE→i，8=MULTILINE→m，10=mi。

// ehd.b case 11
function grammarClike(): CodeGrammar {
  return gram('clike',
    tok('comment',
      patLook(/(^|[^\\])\/\*[\s\S]*?(?:\*\/|$)/),
      patGreedy(/(^|[^\\:])\/\/.*/, true)),
    tok('string',
      patGreedy(/(["'])(?:\\(?:\r\n|[\s\S])|(?!\1)[^\\\r\n])*\1/, false)),
    tok('class-name',
      patInside(/((?:\b(?:class|interface|extends|implements|trait|instanceof|new)\s+)|(?:catch\s+\())[\w.\\]+/,
        true, false, null,
        gram('inside', tok('punctuation', pat(/[.\\]/))))),
    tok('keyword',
      pat(/\b(?:if|else|while|do|for|return|in|instanceof|function|new|try|throw|catch|finally|null|break|continue)\b/)),
    tok('boolean', pat(/\b(?:true|false)\b/)),
    tok('function', pat(/[a-z0-9_]+(?=\()/i)),
    tok('number',
      pat(/\b0x[\da-f]+\b|(?:\b\d+\.?\d*|\B\.\d+)(?:e[+-]?\d+)?/i)),
    tok('operator',
      pat(/--?|\+\+?|!=?=?|<=?|>=?|==?=?|&&?|\|\|?|\?|\*|\/|~|\^|%/)),
    tok('punctuation', pat(/[{}\[\];(),.:]/)));
}

// ehd.b case 0
function grammarCsharp(): CodeGrammar {
  const inside: CodeGrammar =
    gram('inside', tok('punctuation', pat(/\./)));
  const keyword: CodeTokenRule = tok('keyword',
    pat(/\b(?:abstract|add|alias|as|ascending|async|await|base|bool|break|byte|case|catch|char|checked|class|const|continue|decimal|default|delegate|descending|do|double|dynamic|else|enum|event|explicit|extern|false|finally|fixed|float|for|foreach|from|get|global|goto|group|if|implicit|in|int|interface|internal|into|is|join|let|lock|long|namespace|new|null|object|operator|orderby|out|override|params|partial|private|protected|public|readonly|ref|remove|return|sbyte|sealed|select|set|short|sizeof|stackalloc|static|string|struct|switch|this|throw|true|try|typeof|uint|ulong|unchecked|unsafe|ushort|using|value|var|virtual|void|volatile|where|while|yield)\b/));
  const g: CodeGrammar = extendCodeGrammar(codeGrammar('clike') as CodeGrammar,
    'csharp', keyword,
    tok('string',
      patGreedy(/@("|')(?:\1\1|\\[\s\S]|(?!\1)[^\\])*\1/, false),
      patGreedy(/("|')(?:\\.|(?!\1)[^\\\r\n])*?\1/, false)),
    tok('class-name',
      patInside(/\b[A-Z]\w*(?:\.\w+)*\b(?=\s+\w+)/, false, false, null, inside),
      patInside(/(\[)[A-Z]\w*(?:\.\w+)*\b/, true, false, null, inside),
      patInside(/(\b(?:class|interface)\s+[A-Z]\w*(?:\.\w+)*\s*:\s*)[A-Z]\w*(?:\.\w+)*\b/,
        true, false, null, inside),
      patInside(/((?:\b(?:class|interface|new)\s+)|(?:catch\s+\())[A-Z]\w*(?:\.\w+)*\b/,
        true, false, null, inside)),
    tok('number',
      pat(/\b0x[\da-f]+\b|(?:\b\d+\.?\d*|\B\.\d+)f?/i)));
  insertBeforeCodeToken(g, 'class-name',
    tok('generic-method',
      patInside(/\w+\s*<[^>\r\n]+?>\s*(?=\()/, false, false, null,
        gram('inside', tok('function', pat(/^\w+/)),
          tok('class-name',
            patInside(/\b[A-Z]\w*(?:\.\w+)*\b/, false, false, null, inside)),
          keyword, tok('punctuation', pat(/[<>(),.:]/))))),
    tok('preprocessor',
      patInside(/(^\s*)#.*/m, true, false, 'property',
        gram('inside', tok('directive',
          patFlag(/(\s*#)\b(?:define|elif|else|endif|endregion|error|if|line|pragma|region|undef|warning)\b/,
            true, false, 'keyword'))))));
  return g;
}

// ehd.b case 1（lb8：丢弃 clike class-name）
function grammarKotlin(): CodeGrammar {
  const g: CodeGrammar = extendCodeGrammarFiltered(
    codeGrammar('clike') as CodeGrammar, 'kotlin',
    (rule: CodeTokenRule): boolean => rule.name !== 'class-name',
    tok('keyword',
      patLook(/(^|[^.])\b(?:abstract|actual|annotation|as|break|by|catch|class|companion|const|constructor|continue|crossinline|data|do|dynamic|else|enum|expect|external|final|finally|for|fun|get|if|import|in|infix|init|inline|inner|interface|internal|is|lateinit|noinline|null|object|open|operator|out|override|package|private|protected|public|reified|return|sealed|set|super|suspend|tailrec|this|throw|to|try|typealias|val|var|vararg|when|where|while)\b/)),
    tok('function', pat(/\w+(?=\s*\()/),
      patLook(/(\.)\w+(?=\s*\{)/)),
    tok('number',
      pat(/\b(?:0[xX][\da-fA-F]+(?:_[\da-fA-F]+)*|0[bB][01]+(?:_[01]+)*|\d+(?:_\d+)*(?:\.\d+(?:_\d+)*)?(?:[eE][+-]?\d+(?:_\d+)*)?[fFL]?)\b/)),
    tok('operator',
      pat(/\+[+=]?|-[-=>]?|==?=?|!(?:!|==?)?|[\/*%<>]=?|[?:]:?|\.\.|&&|\|\||\b(?:and|inv|or|shl|shr|ushr|xor)\b/)));
  insertBeforeCodeToken(g, 'string',
    tok('raw-string', patFlag(/("""|''')[\s\S]*?\1/, false, false, 'string')));
  insertBeforeCodeToken(g, 'keyword',
    tok('annotation', patFlag(/\B@(?:\w+:)?(?:[A-Z]\w*|\[[^\]]+\])/, false, false, 'builtin')));
  insertBeforeCodeToken(g, 'function',
    tok('label', patFlag(/\w+@|@\w+/, false, false, 'symbol')));
  const interpolationInside: CodeTokenRule[] =
    [tok('delimiter', patFlag(/^\$\{|\}$/, false, false, 'variable'))]
      .concat(g.tokens);
  const insideGrammar: CodeGrammar = gram('inside',
    tok('interpolation',
      patInside(/\$\{[^}]+\}/, false, false, null,
        new CodeGrammar('inside', interpolationInside)),
      patFlag(/\$\w+/, false, false, 'variable')));
  const stringTok: CodeTokenRule | null = findCodeToken(g, ['string']);
  const rawTok: CodeTokenRule | null = findCodeToken(g, ['raw-string']);
  if (stringTok !== null && rawTok !== null) {
    const p0: CodePattern = stringTok.patterns[0];
    const p1: CodePattern = rawTok.patterns[0];
    stringTok.patterns.push(new CodePattern(p0.regex, p0.lookbehind,
      p0.greedy, p0.alias, insideGrammar));
    rawTok.patterns.push(new CodePattern(p1.regex, p1.lookbehind,
      p1.greedy, p1.alias, insideGrammar));
    stringTok.patterns.shift();
    rawTok.patterns.shift();
  }
  return g;
}

// ehd.b case 2
function grammarMarkup(): CodeGrammar {
  const entity: CodeTokenRule = tok('entity', pat(/&#?[\da-z]{1,8};/i));
  return gram('markup',
    tok('comment', pat(/<!--[\s\S]*?-->/)),
    tok('prolog', pat(/<\?[\s\S]+?\?>/)),
    tok('doctype', pat(/<!DOCTYPE[\s\S]+?>/i)),
    tok('cdata', pat(/<!\[CDATA\[[\s\S]*?]]>/i)),
    tok('tag',
      patInside(/<\/?(?!\d)[^\s>\/=$<%]+(?:\s+[^\s>\/=]+(?:=(?:("|')(?:\\[\s\S]|(?!\1)[^\\])*\1|[^\s'">=]+))?)*\s*\/?>/i,
        false, true, null,
        gram('inside',
          tok('tag',
            patInside(/^<\/?[^\s>\/]+/i, false, false, null,
              gram('inside', tok('punctuation', pat(/^<\/?/)),
                tok('namespace', pat(/^[^\s>\/:]+:/))))),
          tok('attr-value',
            patInside(/=(?:(["'])(?:\\[\s\S]|(?!\1)[^\\])*\1|[^\s'">=]+)/i,
              false, false, null,
              gram('inside', tok('punctuation', pat(/^=/)),
                tok('punctuation', patLook(/(^|[^\\])["']/)), entity))),
          tok('punctuation', pat(/\/?>/)),
          tok('attr-name',
            patInside(/[^\s>\/]+/, false, false, null,
              gram('inside', tok('namespace', pat(/^[^\s>\/:]+:/)))))))),
    entity);
}

// ehd.b case 3
function grammarPython(): CodeGrammar {
  return gram('python',
    tok('comment', patLook(/(^|[^\\])#.*/)),
    tok('triple-quoted-string',
      patFlag(/("""|''')[\s\S]+?\1/, false, true, 'string')),
    tok('string', patGreedy(/("|')(?:\\.|(?!\1)[^\\\r\n])*\1/, false)),
    tok('function', patLook(/((?:^|\s)def[ \t]+)[a-zA-Z_]\w*(?=\s*\()/)),
    tok('class-name', patLook(/(\bclass\s+)\w+/i)),
    tok('keyword',
      pat(/\b(?:as|assert|async|await|break|class|continue|def|del|elif|else|except|exec|finally|for|from|global|if|import|in|is|lambda|nonlocal|pass|print|raise|return|try|while|with|yield)\b/)),
    tok('builtin',
      pat(/\b(?:__import__|abs|all|any|apply|ascii|basestring|bin|bool|buffer|bytearray|bytes|callable|chr|classmethod|cmp|coerce|compile|complex|delattr|dict|dir|divmod|enumerate|eval|execfile|file|filter|float|format|frozenset|getattr|globals|hasattr|hash|help|hex|id|input|int|intern|isinstance|issubclass|iter|len|list|locals|long|map|max|memoryview|min|next|object|oct|open|ord|pow|property|range|raw_input|reduce|reload|repr|reversed|round|set|setattr|slice|sorted|staticmethod|str|sum|super|tuple|type|unichr|unicode|vars|xrange|zip)\b/)),
    tok('boolean', pat(/\b(?:True|False|None)\b/)),
    tok('number',
      pat(/(?:\b(?=\d)|\B(?=\.))(?:0[bo])?(?:(?:\d|0x[\da-f])[\da-f]*\.?\d*|\.\d+)(?:e[+-]?\d+)?j?\b/i)),
    tok('operator',
      pat(/[-+%=]=?|!=|\*\*?=?|\/\/?=?|<[<=>]?|>[=>]?|[&|^~]|\b(?:or|and|not)\b/)),
    tok('punctuation', pat(/[{}\[\];(),.:]/)));
}

// ehd.b case 4（ns8：丢弃 clike class-name + boolean）
function grammarC(): CodeGrammar {
  const g: CodeGrammar = extendCodeGrammarFiltered(
    codeGrammar('clike') as CodeGrammar, 'c',
    (rule: CodeTokenRule): boolean =>
      rule.name !== 'class-name' && rule.name !== 'boolean',
    tok('keyword',
      pat(/\b(?:_Alignas|_Alignof|_Atomic|_Bool|_Complex|_Generic|_Imaginary|_Noreturn|_Static_assert|_Thread_local|asm|typeof|inline|auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|int|long|register|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while)\b/)),
    tok('operator',
      pat(/-[>-]?|\+\+?|!=?|<<?=?|>>?=?|==?|&&?|\|\|?|[~^%?*\/]/)),
    tok('number',
      pat(/(?:\b0x[\da-f]+|(?:\b\d+\.?\d*|\B\.\d+)(?:e[+-]?\d+)?)[ful]*/i)));
  insertBeforeCodeToken(g, 'string',
    tok('macro',
      patInside(/(^\s*)#\s*[a-z]+(?:[^\r\n\\]|\\(?:\r\n|[\s\S]))*/mi,
        true, false, 'property',
        gram('inside',
          tok('string',
            patLook(/(#\s*include\s*)(?:<.+?>|("|')(?:\\?.)+?\2)/)),
          tok('directive',
            patFlag(/(#\s*)\b(?:define|defined|elif|else|endif|error|ifdef|ifndef|if|import|include|line|pragma|undef|using)\b/,
              true, false, 'keyword'))))),
    tok('constant',
      pat(/\b(?:__FILE__|__LINE__|__DATE__|__TIME__|__TIMESTAMP__|__func__|EOF|NULL|SEEK_CUR|SEEK_END|SEEK_SET|stdin|stdout|stderr)\b/)));
  return g;
}

// ehd.b case 5（kb8：丢弃 clike class-name）
function grammarGo(): CodeGrammar {
  const g: CodeGrammar = extendCodeGrammarFiltered(
    codeGrammar('clike') as CodeGrammar, 'go',
    (rule: CodeTokenRule): boolean => rule.name !== 'class-name',
    tok('keyword',
      pat(/\b(?:break|case|chan|const|continue|default|defer|else|fallthrough|for|func|go(?:to)?|if|import|interface|map|package|range|return|select|struct|switch|type|var)\b/)),
    tok('boolean', pat(/\b(?:_|iota|nil|true|false)\b/)),
    tok('operator',
      pat(/[*\/%^!=]=?|\+[=+]?|-[=-]?|\|[=|]?|&(?:=|&|\^=?)?|>(?:>=?|=)?|<(?:<=?|=|-)?|:=|\.\.\./)),
    tok('number',
      pat(/(?:\b0x[a-f\d]+|(?:\b\d+\.?\d*|\B\.\d+)(?:e[-+]?\d+)?)i?/i)),
    tok('string', patGreedy(/(["'`])(\\[\s\S]|(?!\1)[^\\])*\1/, false)));
  insertBeforeCodeToken(g, 'boolean',
    tok('builtin',
      pat(/\b(?:bool|byte|complex(?:64|128)|error|float(?:32|64)|rune|string|u?int(?:8|16|32|64)?|uintptr|append|cap|close|complex|copy|delete|imag|len|make|new|panic|print(?:ln)?|real|recover)\b/)));
  return g;
}

// ehd.b case 6
function grammarCpp(): CodeGrammar {
  const g: CodeGrammar = extendCodeGrammar(codeGrammar('c') as CodeGrammar,
    'cpp',
    tok('keyword',
      pat(/\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|class|compl|const|constexpr|const_cast|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|float|for|friend|goto|if|inline|int|int8_t|int16_t|int32_t|int64_t|uint8_t|uint16_t|uint32_t|uint64_t|long|mutable|namespace|new|noexcept|nullptr|operator|private|protected|public|register|reinterpret_cast|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|union|unsigned|using|virtual|void|volatile|wchar_t|while)\b/)),
    tok('operator',
      pat(/--?|\+\+?|!=?|<{1,2}=?|>{1,2}=?|->|:{1,2}|={1,2}|\^|~|%|&{1,2}|\|\|?|\?|\*|\/|\b(?:and|and_eq|bitand|bitor|not|not_eq|or|or_eq|xor|xor_eq)\b/)));
  insertBeforeCodeToken(g, 'function',
    tok('boolean', pat(/\b(?:true|false)\b/)));
  insertBeforeCodeToken(g, 'keyword',
    tok('class-name', patLook(/(class\s+)\w+/i)));
  insertBeforeCodeToken(g, 'string',
    tok('raw-string',
      patFlag(/R"([^()\\ ]{0,16})\([\s\S]*?\)\1"/, false, true, 'string')));
  return g;
}

// ehd.b case 7
function grammarCss(): CodeGrammar {
  const g: CodeGrammar = gram('css',
    tok('comment', pat(/\/\*[\s\S]*?\*\//)),
    tok('atrule',
      patInside(/@[\w-]+?.*?(?:;|(?=\s*\{))/i, false, false, null,
        gram('inside', tok('rule', pat(/@[\w-]+/))))),
    tok('url',
      pat(/url\((?:(["'])(?:\\(?:\r\n|[\s\S])|(?!\1)[^\\\r\n])*\1|.*?)\)/i)),
    tok('selector', pat(/[^{}\s][^{};]*?(?=\s*\{)/)),
    tok('string',
      patGreedy(/("|')(?:\\(?:\r\n|[\s\S])|(?!\1)[^\\\r\n])*\1/, false)),
    tok('property',
      pat(/[-_a-z\xA0-\uFFFF][-\w\xA0-\uFFFF]*(?=\s*:)/i)),
    tok('important', pat(/\B!important\b/i)),
    tok('function', pat(/[-a-z0-9]+(?=\()/i)),
    tok('punctuation', pat(/[(){};:]/)));
  const atruleInside: CodeGrammar | null = tokenInside(g.tokens[1]);
  if (atruleInside !== null) {
    for (const rule of g.tokens) {
      if (rule.name !== 'atrule') {
        atruleInside.tokens.push(rule);
      }
    }
  }
  const markup: CodeGrammar | null = codeGrammar('markup');
  if (markup !== null) {
    insertBeforeCodeToken(markup, 'tag',
      tok('style',
        patInside(/(<style[\s\S]*?>)[\s\S]*?(?=<\/style>)/i, true, true,
          'language-css', g)));
    const tagTok: CodeTokenRule | null = findCodeToken(markup, ['tag']);
    const tagInside: CodeGrammar | null =
      tagTok !== null ? tokenInside(tagTok) : null;
    const tagInsideClone: CodeGrammar | null = tagInside !== null ?
      cloneCodeGrammar(tagInside, new Map()) : null;
    insertBeforeCodeToken(markup, 'tag/attr-value',
      tok('style-attr',
        patInside(/\s*style=("|')(?:\\[\s\S]|(?!\1)[^\\])*\1/i,
          false, false, 'language-css',
          gram('inside',
            tok('attr-name',
              patInside(/^\s*style/i, false, false, null, tagInsideClone)),
            tok('punctuation', pat(/^\s*=\s*['"]|['"]\s*$/)),
            tok('attr-value',
              patInside(/.+/i, false, false, null, g))))));
  }
  return g;
}

// ehd.b case 8
function grammarSql(): CodeGrammar {
  return gram('sql',
    tok('comment',
      patLook(/(^|[^\\])(?:\/\*[\s\S]*?\*\/|(?:--|\/\/|#).*)/)),
    tok('string',
      patGreedy(/(^|[^@\\])("|')(?:\\[\s\S]|(?!\2)[^\\])*\2/, true)),
    tok('variable',
      pat(/@[\w.$]+|@(["'`])(?:\\[\s\S]|(?!\1)[^\\])+\1/)),
    tok('function',
      pat(/\b(?:AVG|COUNT|FIRST|FORMAT|LAST|LCASE|LEN|MAX|MID|MIN|MOD|NOW|ROUND|SUM|UCASE)(?=\s*\()/i)),
    tok('keyword', pat(/\b(?:ACTION|ADD|AFTER|ALGORITHM|ALL|ALTER|ANALYZE|ANY|APPLY|AS|ASC|AUTHORIZATION|AUTO_INCREMENT|BACKUP|BDB|BEGIN|BERKELEYDB|BIGINT|BINARY|BIT|BLOB|BOOL|BOOLEAN|BREAK|BROWSE|BTREE|BULK|BY|CALL|CASCADED?|CASE|CHAIN|CHAR(?:ACTER|SET)?|CHECK(?:POINT)?|CLOSE|CLUSTERED|COALESCE|COLLATE|COLUMNS?|COMMENT|COMMIT(?:TED)?|COMPUTE|CONNECT|CONSISTENT|CONSTRAINT|CONTAINS(?:TABLE)?|CONTINUE|CONVERT|CREATE|CROSS|CURRENT(?:_DATE|_TIME|_TIMESTAMP|_USER)?|CURSOR|CYCLE|DATA(?:BASES?)?|DATE(?:TIME)?|DAY|DBCC|DEALLOCATE|DEC|DECIMAL|DECLARE|DEFAULT|DEFINER|DELAYED|DELETE|DELIMITERS?|DENY|DESC|DESCRIBE|DETERMINISTIC|DISABLE|DISCARD|DISK|DISTINCT|DISTINCTROW|DISTRIBUTED|DO|DOUBLE|DROP|DUMMY|DUMP(?:FILE)?|DUPLICATE|ELSE(?:IF)?|ENABLE|ENCLOSED|END|ENGINE|ENUM|ERRLVL|ERRORS|ESCAPED?|EXCEPT|EXEC(?:UTE)?|EXISTS|EXIT|EXPLAIN|EXTENDED|FETCH|FIELDS|FILE|FILLFACTOR|FIRST|FIXED|FLOAT|FOLLOWING|FOR(?: EACH ROW)?|FORCE|FOREIGN|FREETEXT(?:TABLE)?|FROM|FULL|FUNCTION|GEOMETRY(?:COLLECTION)?|GLOBAL|GOTO|GRANT|GROUP|HANDLER|HASH|HAVING|HOLDLOCK|HOUR|IDENTITY(?:_INSERT|COL)?|IF|IGNORE|IMPORT|INDEX|INFILE|INNER|INNODB|INOUT|INSERT|INT|INTEGER|INTERSECT|INTERVAL|INTO|INVOKER|ISOLATION|ITERATE|JOIN|KEYS?|KILL|LANGUAGE|LAST|LEAVE|LEFT|LEVEL|LIMIT|LINENO|LINES|LINESTRING|LOAD|LOCAL|LOCK|LONG(?:BLOB|TEXT)|LOOP|MATCH(?:ED)?|MEDIUM(?:BLOB|INT|TEXT)|MERGE|MIDDLEINT|MINUTE|MODE|MODIFIES|MODIFY|MONTH|MULTI(?:LINESTRING|POINT|POLYGON)|NATIONAL|NATURAL|NCHAR|NEXT|NO|NONCLUSTERED|NULLIF|NUMERIC|OFF?|OFFSETS?|ON|OPEN(?:DATASOURCE|QUERY|ROWSET)?|OPTIMIZE|OPTION(?:ALLY)?|ORDER|OUT(?:ER|FILE)?|OVER|PARTIAL|PARTITION|PERCENT|PIVOT|PLAN|POINT|POLYGON|PRECEDING|PRECISION|PREPARE|PREV|PRIMARY|PRINT|PRIVILEGES|PROC(?:EDURE)?|PUBLIC|PURGE|QUICK|RAISERROR|READS?|REAL|RECONFIGURE|REFERENCES|RELEASE|RENAME|REPEAT(?:ABLE)?|REPLACE|REPLICATION|REQUIRE|RESIGNAL|RESTORE|RESTRICT|RETURNS?|REVOKE|RIGHT|ROLLBACK|ROUTINE|ROW(?:COUNT|GUIDCOL|S)?|RTREE|RULE|SAVE(?:POINT)?|SCHEMA|SECOND|SELECT|SERIAL(?:IZABLE)?|SESSION(?:_USER)?|SET(?:USER)?|SHARE|SHOW|SHUTDOWN|SIMPLE|SMALLINT|SNAPSHOT|SOME|SONAME|SQL|START(?:ING)?|STATISTICS|STATUS|STRIPED|SYSTEM_USER|TABLES?|TABLESPACE|TEMP(?:ORARY|TABLE)?|TERMINATED|TEXT(?:SIZE)?|THEN|TIME(?:STAMP)?|TINY(?:BLOB|INT|TEXT)|TOP?|TRAN(?:SACTIONS?)?|TRIGGER|TRUNCATE|TSEQUAL|TYPES?|UNBOUNDED|UNCOMMITTED|UNDEFINED|UNION|UNIQUE|UNLOCK|UNPIVOT|UNSIGNED|UPDATE(?:TEXT)?|USAGE|USE|USER|USING|VALUES?|VAR(?:BINARY|CHAR|CHARACTER|YING)|VIEW|WAITFOR|WARNINGS|WHEN|WHERE|WHILE|WITH(?: ROLLUP|IN)?|WORK|WRITE(?:TEXT)?|YEAR)\b/i)),
    tok('boolean', pat(/\b(?:TRUE|FALSE|NULL)\b/i)),
    tok('number',
      pat(/\b0x[\da-f]+\b|\b\d+\.?\d*|\B\.\d+\b/i)),
    tok('operator',
      pat(/[-+*\/=%^~]|&&?|\|\|?|!=?|<(?:=>?|<|>)?|>[>=]?|\b(?:AND|BETWEEN|IN|LIKE|NOT|OR|IS|DIV|REGEXP|RLIKE|SOUNDS LIKE|XOR)\b/i)),
    tok('punctuation', pat(/[;\[\]()`,.]/)));
}

// ehd.b case 9
function grammarJava(): CodeGrammar {
  const keyword: CodeTokenRule = tok('keyword',
    pat(/\b(?:abstract|continue|for|new|switch|assert|default|goto|package|synchronized|boolean|do|if|private|this|break|double|implements|protected|throw|byte|else|import|public|throws|case|enum|instanceof|return|transient|catch|extends|int|short|try|char|final|interface|static|void|class|finally|long|strictfp|volatile|const|float|native|super|while)\b/));
  const g: CodeGrammar = extendCodeGrammar(codeGrammar('clike') as CodeGrammar,
    'java', keyword,
    tok('number',
      pat(/\b0b[01]+\b|\b0x[\da-f]*\.?[\da-fp-]+\b|(?:\b\d+\.?\d*|\B\.\d+)(?:e[+-]?\d+)?[df]?/i)),
    tok('operator',
      patLook(/(^|[^.])(?:\+[+=]?|-[-=]?|!=?|<<?=?|>>?>?=?|==?|&[&=]?|\|[|=]?|\*=?|\/=?|%=?|\^=?|[?:~])/m)));
  insertBeforeCodeToken(g, 'function',
    tok('annotation', patFlag(/(^|[^.])@\w+/, true, false, 'punctuation')));
  insertBeforeCodeToken(g, 'class-name',
    tok('generics',
      patInside(/<\s*\w+(?:\.\w+)?(?:\s*,\s*\w+(?:\.\w+)?)*>/i,
        false, false, 'function',
        gram('inside', keyword, tok('punctuation', pat(/[<>(),.:]/))))));
  return g;
}

// ehd.b case 10
function grammarJson(): CodeGrammar {
  return gram('json',
    tok('property', pat(/"(?:\\.|[^\\"\r\n])*"(?=\s*:)/i)),
    tok('string', patGreedy(/"(?:\\.|[^\\"\r\n])*"(?!\s*:)/, false)),
    tok('number',
      pat(/\b0x[\dA-Fa-f]+\b|(?:\b\d+\.?\d*|\B\.\d+)(?:[Ee][+-]?\d+)?/)),
    tok('punctuation', pat(/[{}\[\]);,]/)),
    tok('operator', pat(/:/)),
    tok('boolean', pat(/\b(?:true|false)\b/i)),
    tok('null', pat(/\bnull\b/i)));
}

// ehd.b case 12
function grammarSwift(): CodeGrammar {
  const g: CodeGrammar = extendCodeGrammar(codeGrammar('clike') as CodeGrammar,
    'swift',
    tok('string',
      patInside(/("|')(\\(?:\((?:[^()]|\([^)]+\))+\)|\r\n|[\s\S])|(?!\1)[^\\\r\n])*\1/,
        false, true, null,
        gram('inside',
          tok('interpolation',
            patInside(/\\\((?:[^()]|\([^)]+\))+\)/, false, false, null,
              gram('inside',
                tok('delimiter',
                  patFlag(/^\\\(|\)$/, false, false, 'variable')))))))),
    tok('keyword',
      pat(/\b(?:as|associativity|break|case|catch|class|continue|convenience|default|defer|deinit|didSet|do|dynamic(?:Type)?|else|enum|extension|fallthrough|final|for|func|get|guard|if|import|in|infix|init|inout|internal|is|lazy|left|let|mutating|new|none|nonmutating|operator|optional|override|postfix|precedence|prefix|private|protocol|public|repeat|required|rethrows|return|right|safe|self|Self|set|static|struct|subscript|super|switch|throws?|try|Type|typealias|unowned|unsafe|var|weak|where|while|willSet|__(?:COLUMN__|FILE__|FUNCTION__|LINE__))\b/)),
    tok('number',
      pat(/\b(?:[\d_]+(?:\.[\de_]+)?|0x[a-f0-9_]+(?:\.[a-f0-9p_]+)?|0b[01_]+|0o[0-7_]+)\b/i)));
  g.tokens.push(tok('constant', pat(/\b(?:nil|[A-Z_]{2,}|k[A-Z][A-Za-z_]+)\b/)));
  g.tokens.push(tok('atrule',
    pat(/@\b(?:IB(?:Outlet|Designable|Action|Inspectable)|class_protocol|exported|noreturn|NS(?:Copying|Managed)|objc|UIApplicationMain|auto_closure)\b/)));
  g.tokens.push(tok('builtin',
    pat(/\b(?:[A-Z]\S+|abs|advance|alignof(?:Value)?|assert|contains|count(?:Elements)?|debugPrint(?:ln)?|distance|drop(?:First|Last)|dump|enumerate|equal|filter|find|first|getVaList|indices|isEmpty|join|last|lexicographicalCompare|map|max(?:Element)?|min(?:Element)?|numericCast|overlaps|partition|print(?:ln)?|reduce|reflect|reverse|sizeof(?:Value)?|sort(?:ed)?|split|startsWith|stride(?:of(?:Value)?)?|suffix|swap|toDebugString|toString|transcode|underestimateCount|unsafeBitCast|with(?:ExtendedLifetime|Unsafe(?:MutablePointers?|Pointers?)|VaList))\b/)));
  const interpolation: CodeTokenRule | null =
    findCodeToken(g, ['string', 'interpolation']);
  const interpolationInside: CodeGrammar | null =
    interpolation !== null ? tokenInside(interpolation) : null;
  if (interpolationInside !== null) {
    for (const rule of g.tokens) {
      interpolationInside.tokens.push(rule);
    }
  }
  return g;
}

// ehd.b case 13
function grammarJavascript(): CodeGrammar {
  const g: CodeGrammar = extendCodeGrammar(codeGrammar('clike') as CodeGrammar,
    'javascript',
    tok('keyword',
      pat(/\b(?:as|async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|from|function|get|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|set|static|super|switch|this|throw|try|typeof|var|void|while|with|yield)\b/)),
    tok('number',
      pat(/\b(?:0[xX][\dA-Fa-f]+|0[bB][01]+|0[oO][0-7]+|NaN|Infinity)\b|(?:\b\d+\.?\d*|\B\.\d+)(?:[Ee][+-]?\d+)?/)),
    tok('function',
      pat(/[_$a-z\xA0-\uFFFF][$\w\xA0-\uFFFF]*(?=\s*\()/i)),
    tok('operator',
      pat(/-[-=]?|\+[+=]?|!=?=?|<<?=?|>>?>?=?|=(?:==?|>)?|&[&=]?|\|[|=]?|\*\*?=?|\/=?|~|\^=?|%=?|\?|\.{3}/)));
  insertBeforeCodeToken(g, 'keyword',
    tok('regex',
      patGreedy(/((?:^|[^$\w\xA0-\uFFFF."'\])\s])\s*)\/(\[[^\]\r\n]+]|\\.|[^/\\\[\r\n])+\/[gimyu]{0,5}(?=\s*($|[\r\n,.;})\]]))/, true)),
    tok('function-variable',
      patFlag(/[_$a-z\xA0-\uFFFF][$\w\xA0-\uFFFF]*(?=\s*=\s*(?:function\b|(?:\([^()]*\)|[_$a-z\xA0-\uFFFF][$\w\xA0-\uFFFF]*)\s*=>))/i,
        false, false, 'function')),
    tok('constant', pat(/\b[A-Z][A-Z\d_]*\b/)));
  const interpolation: CodeTokenRule = tok('interpolation');
  insertBeforeCodeToken(g, 'string',
    tok('template-string',
      patInside(/`(?:\\[\s\S]|\$\{[^}]+\}|[^\\`])*`/, false, true, null,
        gram('inside', interpolation, tok('string', pat(/[\s\S]+/))))));
  const insideTokens: CodeTokenRule[] =
    [tok('interpolation-punctuation',
      patFlag(/^\$\{|\}$/, false, false, 'punctuation'))].concat(g.tokens);
  interpolation.patterns.push(patInside(/\$\{[^}]+\}/, false, false, null,
    new CodeGrammar('inside', insideTokens)));
  const markup: CodeGrammar | null = codeGrammar('markup');
  if (markup !== null) {
    insertBeforeCodeToken(markup, 'tag',
      tok('script',
        patInside(/(<script[\s\S]*?>)[\s\S]*?(?=<\/script>)/i, true, true,
          'language-javascript', g)));
  }
  return g;
}

// ehd.b case 14（extend(markup,0 替换）= 克隆 markup 改名）
function grammarMarkdown(): CodeGrammar {
  const markup: CodeGrammar | null = codeGrammar('markup');
  if (markup === null) {
    return gram('markdown');
  }
  const g: CodeGrammar = extendCodeGrammar(markup, 'markdown');
  const bold: CodeTokenRule = tok('bold',
    patInside(/(^|[^\\])(\*\*|__)(?:(?:\r?\n|\r)(?!\r?\n|\r)|.)+?\2/,
      true, false, null,
      gram('inside', tok('punctuation', pat(/^\*\*|^__|\*\*$|__$/)))));
  const italic: CodeTokenRule = tok('italic',
    patInside(/(^|[^\\])([*_])(?:(?:\r?\n|\r)(?!\r?\n|\r)|.)+?\2/,
      true, false, null,
      gram('inside', tok('punctuation', pat(/^[*_]|[*_]$/)))));
  const url: CodeTokenRule = tok('url',
    patInside(/!?\[[^\]]+\](?:\([^\s)]+(?:[\t ]+"(?:\\.|[^"\\])*")?\)| ?\[[^\]\n]*\])/,
      false, false, null,
      gram('inside',
        tok('variable', patLook(/(!?\[)[^\]]+(?=\]$)/)),
        tok('string', pat(/"(?:\\.|[^"\\])*"(?=\)$)/)))));
  insertBeforeCodeToken(g, 'prolog',
    tok('blockquote', pat(/^>(?:[\t ]*>)*/m)),
    tok('code',
      patFlag(/^(?: {4}|\t).+/m, false, false, 'keyword'),
      patFlag(/``.+?``|`[^`\n]+`/, false, false, 'keyword')),
    tok('title',
      patInside(/\w+.*(?:\r?\n|\r)(?:==+|--+)/, false, false, 'important',
        gram('inside', tok('punctuation', pat(/==+$|--+$/)))),
      patInside(/(^\s*)#+.+/m, true, false, 'important',
        gram('inside', tok('punctuation', pat(/^#+|#+$/))))),
    tok('hr',
      patFlag(/(^\s*)([*-])(?:[\t ]*\2){2,}(?=\s*$)/m, true, false, 'punctuation')),
    tok('list',
      patFlag(/(^\s*)(?:[*+-]|\d+\.)(?=[\t ].)/m, true, false, 'punctuation')),
    tok('url-reference',
      patInside(/!?\[[^\]]+\]:[\t ]+(?:\S+|<(?:\\.|[^>\\])+>)(?:[\t ]+(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\((?:\\.|[^)\\])*\)))?/,
        false, false, 'url',
        gram('inside',
          tok('variable', patLook(/^(!?\[)[^\]]+/)),
          tok('string',
            pat(/(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\((?:\\.|[^)\\])*\))$/)),
          tok('punctuation', pat(/^[\[\]!:]|[<>]/))))),
    bold, italic, url);
  const boldInside: CodeGrammar | null = tokenInside(bold);
  if (boldInside !== null) {
    boldInside.tokens.push(url);
    boldInside.tokens.push(italic);
  }
  const italicInside: CodeGrammar | null = tokenInside(italic);
  if (italicInside !== null) {
    italicInside.tokens.push(url);
    italicInside.tokens.push(bold);
  }
  return g;
}

registerCoreGrammars();
