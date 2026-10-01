# Phase 1398 证据 — 代码块语法高亮：11 个惰性语法（vza.I → yia.java）

## 原版 1.4.2 硬证据

| 证据 | 位置 | 内容 |
|------|------|------|
| 惰性注册表 | `defpackage/vza.java:10` | `vza.I` = 11 名 → `yia` Function1 反射创建器（`fhd..phd.create`）：bash/haskell/lua/matlab/objectivec/ocaml/php/r/racket/ruby/rust |
| 创建器分派 | `defpackage/yia.java` | `invoke` switch 按构造 byte 分派：case8=ruby、9=rust、10=bash、11=haskell、12=lua、13=matlab、14=objectivec、15=ocaml、16→`c(obj)`=php、17→`Constants.REVENUE_AMOUNT_KEY("r")`、18→`I(obj)`=racket |
| bash 子壳名单 | `defpackage/fhd.java` | `fhd.b` = 15 个具名 token（comment/function-name/for-or-select/assign-left/parameter/string/environment/function/keyword/builtin/boolean/file-descriptor/operator/punctuation/number）——`$(...)`/反引号 inside 按名回引主语法 token（共享对象自递归） |
| php 共享件 | `defpackage/lhd.java` | `b`=punctuation、`c`=operator、`d`=number(‑i)、`e`=comment 四个静态 Pattern；`a(zmi)`=5-pattern 字符串 token（nowdoc/heredoc/backtick/single/double 引号，双引+heredoc inside 含插值 token） |
| racket number | `defpackage/nhd.java` | `nhd.b` = `cle.q` 四段拼接的大数字正则（十进制/#box 进制/精确度/复数），flag 2=i |
| 集合工具 | `e52.N3`/`oag.x2`/`oag.y2` | N3=collection 拼接、x2=listOf(单)、y2=listOf(vararg)——php attribute inside 的 token 拼装用 |
| token 移除 | `yia.java:275-305,383-396` | ruby 按名摘 `function`/`string`、objectivec 按名摘 `class-name`（`List.remove(indexOf)`，找不到 i=-1 跳过） |

## 原版行为要点

- ruby：`rgm.d(clike)` 派生后摘 `function`，四处 `insertBefore`（operator←double-colon、keyword←regex-literal/variable/symbol/method-definition、string←string-literal+command-literal、number←builtin+constant），随后再摘 `string`；`content` token 的 inside 指回整个 ruby 语法（`#{...}` 内自递归）。
- rust：`closure-params` 的 inside = `[closure-punctuation] + 全 rust token`（含自身，自递归）；`attribute` inside 只含 string token。
- bash：字符串/heredoc inside = `[bash(命令行), environment, variable, entity]`；`bash` token 的 pattern inside=全语法；`$(...)`/`` ` `` inside 先放界定 variable，再按 fhd.b 名单追加主语法 15 token。
- php：`attribute`(`#[...]`) 的 inside = attribute-content(inside=[comment, string 组, attribute-class-name, constant, number, operator, punctuation]) + delimiter；`interpolation` token 建语法后追加 inside=全语法的 `{$...}`/`$var` pattern。
- objectivec：`rgm.d(c)` 派生（非 clike）+ @ 指令关键字并摘 `class-name`。

## Harmony 移植（`CodeSyntaxHighlighter.ets` 惰性语法段）

- 11 个 `grammarX()` 创建器按 yia case 序排布，`registerCoreGrammars` 尾部注册——
  `vza.H` 26 名从此全量可构建，别名链（sh/shell→bash、objc、rs、rb、hs）自动生效。
- 转写约定：本段所有 `Pattern.compile("...", N)` 的 Java 字符串字面量逐字落进
  `new RegExp("...", flags)`（2→i、8→m、10→mi），零重转写误差。
- 复用件：`BASH_ENV_NAMES`（bash 三处环境变量表）、`PHP_COMMENT/NUMBER/OPERATOR/PUNCT_SRC`
  （lhd 静态）、`phpStringToken()`（lhd.a）、`phpNsInside()`（每处 ehd.a("inside") 新对象
  等价的工厂）、`RACKET_NUMBER_SRC`（cle.q 四段拼接）、`BASH_SUBSHELL_TOKENS`（fhd.b）。
- 结构操作：`removeCodeToken`（ruby/objectivec 的 list.remove）、`insertBeforeCodeToken`、
  `extendCodeGrammar`、`CodeTokenRule.patterns.push`（zmiVar.b.add 后置 inside 自递归）。

## 有界差异

- bash `assign-left` 原版正则尾 `(?=\+=)`（decompiled 逐字；与上游 prism-bash
  `\+?=` 略有出入，按 decompiled 忠实移植）。
- Java `\b` 区域语义差异沿用 ADR-1333 登记；惰性语法同样适用。

## 验证

- tsc 转译 + node 样例自验：11 语言全部产出正确类目/偏移/颜色 span；
  shell/sh/objc/rs/rb/hs 六个别名解析正确。
- `note@default` BUILD SUCCESSFUL（CompileArkTS 无新增错误）。
- `d02-original-code-block-syntax-highlight-lazy.mjs`：44 项结构断言全绿。
