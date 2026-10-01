# Phase 1397 — 原版代码块语法高亮（Prism4j 引擎 + 核心 15 语法）

- ADR：`docs/migration/adr/ADR-1333-original-code-block-syntax-highlight.md`
- 证据：`docs/migration/evidence/phase-1397-original-code-block-syntax-highlight.md`
- Replay：`docs/migration/replays/d02-original-code-block-syntax-highlight.mjs`（59 项）

## 背景

审计总纲已登记代码块语法高亮缺口：原版 `o3i.c` 对 CODE_BLOCK 段落
（有 `programmingLanguage` 时）调用 `io.noties.prism4j` 分词引擎
（`ehd.java`），经 `ynh.a` 提取类目 span、`o3i.b` 静态调色板着色
（GitHub-light 系）。Harmony 此前仅应用等宽面（`applyCodeBlockFace`
familyName/fontSize），无任何着色。

## 原版行为（硬证据）

- `ehd.i` 分词 + `ehd.c` matchGrammar 核心循环：greedy 全文本区域匹配、
  oneShot 递归（target token 截断）、lookbehind=捕获组 1 前缀截除、
  `SyntaxImpl.tokenized=hasInside`、deleteCount≠1 时重跑更早 token。
  两处 JADX 伪影经上游 Prism4j 源码校正：贪心未命中=break、match 起点
  落 token 内=continue。
- `rgm.d/c/g/h/f/e` 语法派生（克隆+替换/谓词过滤/路径下钻 insertBefore/
  findToken/insideOf）+ `c9n` identityHashCode 深拷贝；`ns8/kb8/lb8`
  谓词（C 丢 class-name+boolean、Go/Kotlin 丢 class-name）。
- `ynh.f` 40 token 名→16 个 `bni` 类目（alias 回落+父类目继承）；
  `o3i.b` 类目→ARGB 调色板逐位定值。
- `vza.h` 别名（typescript→javascript、sh/shell→bash、objc/rs/rb/hs、
  dotnet→csharp、xml/html/svg/mathml→markup、js、jsonp）+ `vza.H`
  26 名支持集（15 内建 + 11 惰性）。
- markup 热切 javascript/css 回注 `script`/`style` token（`<script>`/
  `<style>` 内按对应语法着色）。

## Harmony 实现

新增 `note/src/main/ets/core/adaptation/CodeSyntaxHighlighter.ets`
（~1024 行）：

- `matchCodeGrammar`/`tokenizeCode` 逐语义移植 Prism4j.matchGrammar；
- `extendCodeGrammar`/`extendCodeGrammarFiltered`/`insertBeforeCodeToken`/
  `findCodeToken`/`tokenInside` + `cloneCodeGrammar`（Map 键即 identity）；
- `TOKEN_CATEGORY` 全 40 映射 + `CATEGORY_COLORS` 全 16 ARGB；
- `CODE_LANG_ALIASES` 全别名 + `SUPPORTED_CODE_LANGS` 全 26；
- `grammarCache` 惰性构建 + 失败哨兵；markup 热切时序保留；
- 本 Phase 注册 15 个内建语法创建器；其余 11 惰性语法留 Phase 1398。

`Canvas2DTextRenderer.applyCodeBlockFace` 签名 `length:number` →
`characters:string[]`：等宽面照旧，随后按 `\n` 切段逐段取
`programmingLanguage` → `codeBlockHighlightSpans` → span 区间字符
`foregroundColor` 覆盖（等价原版 `uog` 掩码仅设 color）。颜色只落到
渲染期瞬态样式数组，持久化 `characterStyleRuns` 不动。

## 有界差异

1. 11 个惰性语法本 Phase 返回空 span（原版语法构建失败时同此视觉），
   Phase 1398 补 `yia.java` 创建器后自动生效。
2. Java `Matcher.region` 的 `\b` 能看到区域起点前字符，JS `substring`
   等价写法失去该上文；现存语法中无 `\b` 引导贪心 pattern 依赖此边界。
3. `uog` 其余字段原为空掩码——Harmony 由既有 face 逻辑等价覆盖。

## 验证

- tsc 转译 + node 功能自验：15 语法样例全部产出正确类目/偏移/颜色 span；
  typescript 别名白得；plaintext/未支持语言空 span。
- `note@default` BUILD SUCCESSFUL（CompileArkTS 无新增错误）。
- `note@ohosTest` BUILD SUCCESSFUL。
- 全量 Desktop Replay：新增 59 项断言全绿；`d02-original-quote-code-blocks`
  按新签名更新钉线。

## 后续

Phase 1398：补齐 `vza.I` 对应 `yia.java` 的 11 个惰性语法创建器
（bash/haskell/lua/matlab/objectivec/ocaml/php/r/racket/ruby/rust）。
