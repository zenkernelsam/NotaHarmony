// Phase 1397 — 原版 1.4.2 Prism4j 代码块语法高亮移植回归。
// 原版证据：ehd.java（matchGrammar/tokenize 分词引擎 + grammar() 分发）、
// mnc/zmi/zm6/s3i/znh（Pattern/Token/Grammar/Text/Syntax 节点）、
// rgm.java（extend/insertBefore/findToken/insideOf 语法派生）、
// c9n.b/c（identity 表深拷贝）、ynh.java（token 名→bni 类目 + 递归 span）、
// o3i.b（bni 类目→ARGB 调色板）、o3i.c（CODE_BLOCK 段落布局期着色）、
// vza.java（别名解析 + 26 语言支持集）。
// Harmony：CodeSyntaxHighlighter.ets 引擎+核心 15 语法；
// Canvas2DTextRenderer.applyCodeBlockFace 内按段落 token span 覆盖
// foregroundColor（不改持久化 run，未着色区间保留原字色）。
import { readFileSync } from 'node:fs';

const highlighter = readFileSync(
  'note/src/main/ets/core/adaptation/CodeSyntaxHighlighter.ets', 'utf8');
const renderer = readFileSync(
  'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets', 'utf8');

let passed = 0;
let failed = 0;
const check = (ok, label) => {
  if (ok) {
    passed += 1;
  } else {
    failed += 1;
    console.log(`FAIL ${label}`);
  }
};

// —— 引擎骨架（ehd.c matchGrammar 关键语义）——
check(highlighter.includes('function matchCodeGrammar(text: string, entries: CodeNode[], grammar: CodeGrammar'),
  'matchGrammar 引擎函数');
check(highlighter.includes('rule === target'),
  'oneShot 递归按 target token 截断（原版 token == tokenToSkip 时 return）');
check(highlighter.includes('greedy && i !== entries.length - 1'),
  'greedy 仅在非末节点走全文本区域匹配');
check(highlighter.includes('!isSyntaxNode(entries[k]) &&') &&
  highlighter.includes('!isGreedyNode(entries[k - 1])'),
  '贪心走查终止条件：越过 match 尾后遇 token 或前驱贪心 token 即停');
check(highlighter.includes('deleteCount !== 1') &&
  highlighter.includes('matchCodeGrammar(text, entries, grammar, i, position, true, rule)'),
  '跨多节点贪心命中后 oneShot 重跑更早 token');
check(highlighter.includes('entries.splice(i2, 0, syntax)') &&
  highlighter.includes('syntax.tokenized = hasInside'),
  'Syntax 节点携带 tokenized=hasInside 标记（znh.f）');
check(highlighter.includes('lookbehindLength > 0 ?') &&
  highlighter.includes('matched[0].substring(lookbehindLength)'),
  'lookbehind 用捕获组 1 长度截掉前缀（Prism4j 安卓无原生 lookbehind）');

// —— 语法派生工具（rgm/c9n）——
check(highlighter.includes('function extendCodeGrammar(') &&
  highlighter.includes('function extendCodeGrammarFiltered('),
  'rgm.d/c：extend 与过滤 extend（克隆基语法+原位替换）');
check(highlighter.includes('function insertBeforeCodeToken') &&
  highlighter.includes("path.split('.')"),
  'rgm.g/h：insertBefore 按 a.b 路径下钻 inside 语法');
check(highlighter.includes('function findCodeToken') &&
  highlighter.includes('function tokenInside'),
  'rgm.f/e：findToken 下钻 + tokenInside 取首 pattern inside');
check(highlighter.includes('function cloneCodeGrammar') &&
  highlighter.includes('seen: Map<object, object>'),
  'c9n：identity 表深拷贝防环');

// —— 类目与调色板（ynh.f + o3i.b）——
for (const pair of [
  "['keyword', 'KEYWORD']", "['string', 'STRING']",
  "['comment', 'COMMENT']", "['function', 'FUNCTION']",
  "['class-name', 'CLASS_NAME']", "['number', 'NUMBER']",
  "['boolean', 'CONSTANT']", "['punctuation', 'PUNCTUATION']",
  "['tag', 'TAG']", "['regex', 'REGEX']", "['builtin', 'BUILTIN']",
  "['decorator', 'DECORATOR']", "['attr-value', 'STRING']",
]) {
  check(highlighter.includes(pair), `token→类目映射 ${pair}`);
}
for (const color of [
  "['KEYWORD', 0xFFD73A49]", "['STRING', 0xFF032F62]",
  "['COMMENT', 0xFF6A737D]", "['FUNCTION', 0xFF6F42C1]",
  "['CLASS_NAME', 0xFFE36209]", "['PUNCTUATION', 0xFF24292E]",
  "['TAG', 0xFF22863A]",
]) {
  check(highlighter.includes(color), `o3i.b 调色板 ${color}`);
}
check(highlighter.includes('node.alias !== null && node.alias.length > 0'),
  'ynh.a：token 类目缺失时回落 alias 类目');
check(highlighter.includes('category ?? null') &&
  highlighter.includes('collectCodeSpans(node.children, position'),
  'ynh.a：children 递归继承父类目且位置单次消费');

// —— 语言注册表（vza.h/vza.H/ehd.b）——
for (const alias of [
  "['typescript', 'javascript']", "['sh', 'bash']", "['objc', 'objectivec']",
  "['rs', 'rust']", "['rb', 'ruby']", "['hs', 'haskell']",
  "['xml', 'markup']", "['jsonp', 'json']",
]) {
  check(highlighter.includes(alias), `vza.h 别名 ${alias}`);
}
check(highlighter.includes("'racket', 'ruby', 'rust'"),
  'vza.H 支持集含 26 名（11 个惰性语法创建器于 Phase 1398 注册）');
check(highlighter.includes("CODE_GRAMMAR_CREATORS.set('clike'") &&
  highlighter.includes("CODE_GRAMMAR_CREATORS.set('javascript'") &&
  highlighter.includes("CODE_GRAMMAR_CREATORS.set('markdown'"),
  'ehd.b：15 个内建语法创建器注册');
check(highlighter.includes("canonical === 'markup'") &&
  highlighter.includes("codeGrammar('javascript')") &&
  highlighter.includes("codeGrammar('css')"),
  'ehd.b 尾部：markup 构建后热切 javascript/css 完成 script/style 互注');
check(highlighter.includes('grammarCache.set(canonical, grammar)'),
  'ehd.b map：构建结果缓存（null=wzaVar 失败哨兵）');

// —— 各语法关键规则存在性抽查 ——
check(highlighter.includes("patLook(/(^|[^.])\\b(?:abstract|actual|annotation|as|break|by|catch"),
  'kotlin keyword lookbehind (^|[^.]) 防点调用误判');
check(highlighter.includes('interpolationInside.tokens.push(rule)'),
  'swift：interpolation inside 汇入全部 token');
check(highlighter.includes("patInside(/(<script[\\s\\S]*?>)[\\s\\S]*?(?=<\\/script>)/i") &&
  highlighter.includes("'language-javascript'"),
  'javascript→markup 注入 script token（alias=language-javascript）');
check(highlighter.includes("patInside(/(<style[\\s\\S]*?>)[\\s\\S]*?(?=<\\/style>)/i") &&
  highlighter.includes("'language-css'"),
  'css→markup 注入 style token（alias=language-css）');
check(highlighter.includes("insertBeforeCodeToken(markup, 'tag/attr-value'"),
  'css→markup tag/attr-value 路径注入 style-attr');
check(highlighter.includes('codeGrammar(\'markup\')') &&
  highlighter.includes("if (markup === null)") &&
  highlighter.includes("extendCodeGrammar(markup, 'markdown')"),
  'markdown = extend(markup) 克隆改名');
check(highlighter.includes("rule.name !== 'class-name' && rule.name !== 'boolean'"),
  'c 语法丢弃 class-name/boolean（ns8）');
check(highlighter.includes('isFinite') === false,
  '无 isFinite 误用');

// —— 公开 API 与失败兜底（o3i.c：异常→空 span 保持代码字面无高亮）——
check(highlighter.includes('export function codeBlockHighlightSpans(text: string,') &&
  highlighter.includes('try {') &&
  highlighter.includes('tokenizeCode(text, grammar)') &&
  highlighter.includes('} catch (e) {'),
  '公开入口分词异常 fail-closed 为空 span（原版 catch 同义）');

// —— 渲染接线（o3i.c：段落级 programmingLanguage → token span 覆盖色）——
check(renderer.includes("import {") &&
  renderer.includes("codeBlockHighlightSpans, CodeStyleSpan,") &&
  renderer.includes("from './CodeSyntaxHighlighter'"),
  '渲染器引入高亮引擎');
check(renderer.includes('paragraphStyles: RichTextParagraphStyle[], characters: string[]'),
  'applyCodeBlockFace 改收 characters（供段落切分分词）');
// Phase 1479：caretRectAtIndex（caretIndexAtPoint 逆运算）同核 → 6 处。
check((renderer.match(/this\.applyCodeBlockFace\(characterStyles, paragraphStyles, characters,/g) ?? []).length === 6,
  'measure/layout/render/hit/caret-rect 六处调用点保持统一');
check(renderer.includes('paragraph.programmingLanguage') &&
  renderer.includes('paragraph.decoratorStyle === 5 && language !== undefined'),
  '仅 CODE_BLOCK(5) + programmingLanguage 段落着色（原版 kom.w==CODE_BLOCK 且 cve.a 非空）');
check(renderer.includes('codeStyle.foregroundColor = span.color'),
  'span 只覆盖 foregroundColor（uog 仅设 color），其余字形样式保留');

console.log(`checks=${passed + failed} pass=${passed} fail=${failed}`);
if (failed > 0) {
  process.exit(1);
}
