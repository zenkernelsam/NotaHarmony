// Phase 1398 — 原版 1.4.2 Prism4j 惰性语法集（vza.I → yia.java）11 语法移植回归。
// 原版证据：vza.java:10 惰性注册表（yia Function1 反射创建器 case 8..18）、
// yia.java 各 case 语法体、fhd.b（bash 子壳 inside 复用 15 名 token 名单）、
// lhd.b/c/d/e + lhd.a（php 共享 pattern/字符串 token 组）、nhd.b（racket number
// 四段拼接）、e52.N3/oag.x2/y2（list 拼接/listOf）。
// Harmony：CodeSyntaxHighlighter.ets 惰性语法段（case 序 8..18 逐字落
// new RegExp("java字面量", flags)），26/26 语言全量注册。
import { readFileSync } from 'node:fs';

const highlighter = readFileSync(
  'note/src/main/ets/core/adaptation/CodeSyntaxHighlighter.ets', 'utf8');

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

// —— 注册表：vza.I 11 名全部挂创建器 ——
for (const lang of ['bash', 'haskell', 'lua', 'matlab', 'objectivec', 'ocaml',
  'php', "'r'", 'racket', 'ruby', 'rust']) {
  const key = lang === "'r'" ? 'r' : lang;
  check(highlighter.includes(`CODE_GRAMMAR_CREATORS.set('${key}', grammar`),
    `vza.I 创建器注册 ${key}`);
}
check(highlighter.includes('function grammarBash()') &&
  highlighter.includes('function grammarHaskell()') &&
  highlighter.includes('function grammarLua()') &&
  highlighter.includes('function grammarMatlab()') &&
  highlighter.includes('function grammarObjectivec()') &&
  highlighter.includes('function grammarOcaml()') &&
  highlighter.includes('function grammarPhp()') &&
  highlighter.includes('function grammarR()') &&
  highlighter.includes('function grammarRacket()') &&
  highlighter.includes('function grammarRuby()') &&
  highlighter.includes('function grammarRust()'),
  '11 个语法创建器函数齐备（yia case 8..18）');
check(highlighter.includes('function removeCodeToken('),
  '同名 token 移除（ruby function / objectivec class-name）');

// —— ruby（case 8：extend clike + 自递归插值）——
check(highlighter.includes("extendCodeGrammar(codeGrammar('clike') as CodeGrammar,\n    'ruby'"),
  'ruby = rgm.d(clike) 派生');
check(highlighter.includes("removeCodeToken(g, 'function')") &&
  highlighter.includes("removeCodeToken(g, 'string')"),
  'ruby 移除 clike function/string token（list.remove 等价）');
check(highlighter.includes("insertBeforeCodeToken(g, 'operator'") &&
  highlighter.includes("insertBeforeCodeToken(g, 'keyword'") &&
  highlighter.includes("insertBeforeCodeToken(g, 'string'") &&
  highlighter.includes("insertBeforeCodeToken(g, 'number'"),
  'ruby 四处 insertBefore（double-colon/regex-literal 系/string-literal 系/builtin 系）');
check(highlighter.includes("tok('interpolation',") &&
  highlighter.includes("tok('content');") &&
  highlighter.includes('contentTok.patterns.push('),
  'ruby 插值 token + content 自递归 inside=全语法');
check(highlighter.includes("'heredoc-string'") &&
  highlighter.includes("'command-literal'") &&
  highlighter.includes("'regex-literal'") &&
  highlighter.includes("'method-definition'"),
  'ruby heredoc/command/regex/method-def token 齐备');

// —— rust（case 9：closure-params inside = 标点+全语法自递归）——
check(highlighter.includes("tok('closure-params');") &&
  highlighter.includes('closureParams.patterns.push(') &&
  highlighter.includes('.concat(g.tokens)'),
  'rust closure-params inside=[closure-punctuation]+全 token（自递归）');
check(highlighter.includes("'lifetime-annotation'") &&
  highlighter.includes("'fragment-specifier'") &&
  highlighter.includes("'module-declaration'") &&
  highlighter.includes("'function-definition'") &&
  highlighter.includes("'type-definition'"),
  'rust 专属 token：lifetime/fragment/module-decl/fn-def/type-def');

// —— bash（case 10：fhd.b 子壳 inside 复用 15 具名 token）——
check(highlighter.includes('BASH_SUBSHELL_TOKENS') &&
  highlighter.includes("'for-or-select'") &&
  highlighter.includes("'assign-left'") &&
  highlighter.includes("'file-descriptor'"),
  'bash fhd.b 名单内 token 齐备');
check(highlighter.includes('subshellInside.tokens.push(rule)') &&
  highlighter.includes('byName.set(rule.name, rule)'),
  'bash $(...)/反引号 inside 按名复用主语法 token（共享对象）');
check(highlighter.includes("tok('shebang',") &&
  highlighter.includes("'important'"),
  'bash shebang alias=important');
check(highlighter.includes("tok('bash');") &&
  highlighter.includes('bashTok.patterns.push('),
  'bash 字符串内 cmd 行 token inside=全语法（zmiVarH5）');
check(highlighter.includes('BASH_ENV_NAMES'),
  'bash 环境变量名表（3 处复用去重）');

// —— haskell（case 11）——
check(highlighter.includes("tok('import-statement',") &&
  highlighter.includes("tok('hvariable',") &&
  highlighter.includes('zipWith3'),
  'haskell import-statement/hvariable/builtin 长表');

// —— lua / matlab（case 12/13）——
check(highlighter.includes('\\\\z(?:\\\\r\\\\n|\\\\s)') &&
  highlighter.includes('function grammarLua'),
  'lua 字符串含 \\z 续行转义');
check(highlighter.includes('patGreedy(new RegExp("\\\\B\'(?:\'\'|[^\'\\\\r\\\\n])*\'")') &&
  highlighter.includes('function grammarMatlab'),
  'matlab 字符串 \\B\'…\' 与运算符');

// —— objectivec（case 14：extend c + 摘 class-name）——
check(highlighter.includes("extendCodeGrammar(codeGrammar('c') as CodeGrammar,\n    'objectivec'") &&
  highlighter.includes("removeCodeToken(g, 'class-name')") &&
  highlighter.includes('@interface|@end'),
  'objectivec = rgm.d(c) + @ 关键字 + 摘 class-name');

// —— ocaml（case 15）——
check(highlighter.includes("'operator-like-punctuation'") &&
  highlighter.includes("'type-variable'") &&
  highlighter.includes("tok('variant'"),
  'ocaml 专属 token：operator-like-punctuation/type-variable/variant');

// —— php（case 16：lhd.b/c/d/e + lhd.a）——
check(highlighter.includes('PHP_COMMENT_SRC') &&
  highlighter.includes('PHP_NUMBER_SRC') &&
  highlighter.includes('PHP_OPERATOR_SRC') &&
  highlighter.includes('PHP_PUNCT_SRC'),
  'php lhd.b/c/d/e 共享 pattern 常量');
check(highlighter.includes('function phpStringToken(') &&
  highlighter.includes("'nowdoc-string'") &&
  highlighter.includes("'heredoc-string'") &&
  highlighter.includes("'backtick-quoted-string'") &&
  highlighter.includes("'single-quoted-string'") &&
  highlighter.includes("'double-quoted-string'"),
  'php lhd.a 字符串 token 组（5 pattern 含插值回引）');
check(highlighter.includes("'class-name-fully-qualified'") &&
  highlighter.includes("'type-casting'") &&
  highlighter.includes("'type-hint'") &&
  highlighter.includes("'return-type'") &&
  highlighter.includes("'static-context'"),
  'php 14-pattern class-name 别名族 + keyword 类型别名');
check(highlighter.includes("'attribute-content'") &&
  highlighter.includes("'attribute-class-name'"),
  'php #[...] attribute 二段 inside');
check(highlighter.includes('interpolationTok.patterns.push(') &&
  highlighter.includes('function phpNsInside()'),
  'php 插值 inside=全语法自递归 + nsInside 工厂');

// —— r（case 17）——
check(highlighter.includes("'percent-operator'") &&
  highlighter.includes("'ellipsis'") &&
  highlighter.includes('NA_character_'),
  'r 专属 token：percent-operator/ellipsis/NA_ 系');

// —— racket（case 18：nhd.b 四段拼接 number）——
check(highlighter.includes('RACKET_NUMBER_SRC') &&
  highlighter.includes("'lambda-parameter'") &&
  highlighter.includes("'identifier'") &&
  highlighter.includes('^#lang'),
  'racket nhd.b 拼接 number + lambda-parameter/#lang');

// —— 别名链通惰性语法 ——
for (const alias of [
  "['shell', 'bash']", "['sh', 'bash']", "['objc', 'objectivec']",
  "['rs', 'rust']", "['rb', 'ruby']", "['hs', 'haskell']",
]) {
  check(highlighter.includes(alias), `vza.h 惰性别名 ${alias}`);
}

// —— fail-soft 保持：未知语言仍空 span ——
check(highlighter.includes('if (!SUPPORTED_CODE_LANGS.has(canonical))'),
  '未支持语言早退空 span（o3i.c 同义）');

console.log(`checks=${passed + failed} pass=${passed} fail=${failed}`);
if (failed > 0) {
  process.exit(1);
}
