# Phase 1397 证据 — 代码块语法高亮（Prism4j 移植）

## 原版 1.4.2 硬证据

| 证据 | 位置 | 内容 |
|------|------|------|
| 分词引擎 | `defpackage/ehd.java` | `i()`=tokenize 入口、`c()`=matchGrammar 核心循环（greedy 全文本区域匹配、oneShot 重跑、lookbehind 捕获组 1）、`b()`=grammar(name) 惰性构建 + 15 个内建语法分派 |
| 节点模型 | `s3i/znh/zmi/mnc/zm6/chd/dhd` | Text/Syntax 节点、Token、Pattern（regex/lookbehind/greedy/alias/inside）、Grammar |
| 语法派生 | `defpackage/rgm.java` | `d`=extend（克隆+同名替换）、`c`=extend+谓词过滤、`g/h`=insertBefore 按 `a.b` 路径下钻 inside、`f`=findToken、`e`=insideOf |
| 深拷贝 | `defpackage/c9n.java` | `b/c`：identityHashCode 表防环的 grammar/token 深拷贝 |
| token→类目 | `defpackage/ynh.java` | `f` 表 40 个 token 名→16 个 bni 类目；`a()` 递归提取 ny6 span（alias 回落 + 父类目继承） |
| 类目→颜色 | `defpackage/o3i.java` | `b` 静态表：bni 序号→ARGB（GitHub-light 系：KEYWORD/OPERATOR=#D73A49、STRING/REGEX=#032F62、COMMENT=#6A737D、FUNCTION/DECORATOR=#6F42C1、CLASS_NAME/PROPERTY/VARIABLE=#E36209、NUMBER/CONSTANT/BUILTIN/STRING_ESCAPE=#005CC5、PUNCTUATION=#24292E、TAG=#22863A） |
| 应用点 | `o3i.c` | `kom.w(set)==CODE_BLOCK` 且 `wwe.o(set)` 语言非空 → `ehd.i` 分词 → `ynh.a` span → `uog` 仅设 color 覆盖；异常（IllegalArgument/IllegalState/IndexOOB/SOF）→ 空 span 无高亮 |
| 语言注册 | `defpackage/vza.java` | `h()` 别名：typescript→javascript、sh/shell→bash、objc→objectivec、rs→rust、rb→ruby、hs→haskell、dotnet→csharp、xml/html/svg/mathml→markup、js→javascript、jsonp→json；`H` 支持集=15 内建+11 惰性语法（vza.I） |
| 引擎身份 | `ehd/rgm` 结构 | 即开源 io.noties.prism4j（上游 Prism4j.java/GrammarUtils 比对确认语义） |
| 派生过滤 | `ns8/kb8/lb8.java` | C 丢 class-name+boolean；Go/Kotlin 丢 class-name |

## 原版行为要点

- CODE_BLOCK 段落（`kom.w==ak3.CODE_BLOCK`）按段级 `programmingLanguage`
  （`cve.a`）取语法；无语言 → 仅等宽字面无高亮。
- 分词在**段落文本**上做；span 颜色经 `t00.o/l` 覆盖为该段代码文字样式，
  用户显式 run 的其余属性（粗斜体等）由 uog 掩码 65534 保留、仅 color 被换。
- markup 构建时热切构建 javascript/css，二者回注 `script`/`style` token
  进 markup（`language-*` alias）——`<script>`/`<style>` 内按对应语法着色。
- kotlin/swift/javascript 的字符串插值 inside 语法回引宿主语法（自递归）。

## Harmony 移植

`note/src/main/ets/core/adaptation/CodeSyntaxHighlighter.ets`（新增 ~1000 行）：

- `matchCodeGrammar/tokenizeCode` 逐语义移植 Prism4j.matchGrammar
  （经上游源码校正两处 JADX 伪影：贪心未命中=break、match 起点落在 token
  内=continue 跳节点）；
- `extendCodeGrammar/extendCodeGrammarFiltered/insertBeforeCodeToken/
  findCodeToken/tokenInside` + `cloneCodeGrammar`（Map 键即 identity，
  等价 identityHashCode 表）；
- `TOKEN_CATEGORY`（ynh.f 全 40 项）+ `CATEGORY_COLORS`（o3i.b 全 16 类目）；
- `CODE_LANG_ALIASES`（vza.h 全别名）+ `SUPPORTED_CODE_LANGS`（vza.H 全 26）；
- `grammarCache`（ehd.b map；null=失败哨兵 wzaVar）；markup 热切 js/css 保留；
- 本 Phase 注册 15 个内建语法（clike/c/cpp/csharp/css/go/java/javascript/
  json/kotlin/markdown/markup/python/sql/swift）；typescript 经别名白得。
  其余 11 个惰性语法（bash/haskell/lua/matlab/objectivec/ocaml/php/r/
  racket/ruby/rust）留 Phase 1398（vza.I 对应 yia.java 创建器）。

`Canvas2DTextRenderer.applyCodeBlockFace`（签名 `length`→`characters`）：
等宽面处理后按 `\n` 切段，逐段 `decoratorStyle===5 && programmingLanguage`
→ `codeBlockHighlightSpans` → span 区间字符 `foregroundColor` 覆盖；
未命中区间保留原颜色。measure/layout/render/hit 五处调用点不变。

## 有界差异

1. **惰性语法集未全量**：11 个 vza.I 惰性语法暂返回空 span（代码字面保持
   等宽无高亮——与原版 `chdVarB==null→em4.F` 同表现），Phase 1398 补齐。
2. **Java `\b` 区域边界语义**：原版贪心匹配用 `Matcher.region(position,end)`，
   `\b` 能看到区域起点前的字符；JS `substring` 截断失去该上文——仅当
   `\b` pattern 恰好在 token 边界且左邻为 `\w` 字符时可能差一拍，实际语法中
   该形态罕见（贪心 pattern 多以非 `\b` 前缀引导），登记为近似。
3. `uog` 其余字段（字族/字号/字距）原为空掩码走段基样式——Harmony 侧
   已由 applyCodeBlockFace 既有 monospace/fontSize 逻辑覆盖等价效果。
