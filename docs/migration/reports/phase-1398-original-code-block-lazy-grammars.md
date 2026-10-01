# Phase 1398 — 原版代码块语法高亮：11 个惰性语法（vza.I → yia.java）

- ADR：`docs/migration/adr/ADR-1334-original-code-block-lazy-grammars.md`
- 证据：`docs/migration/evidence/phase-1398-original-code-block-lazy-grammars.md`
- Replay：`docs/migration/replays/d02-original-code-block-syntax-highlight-lazy.mjs`（44 项）

## 背景

Phase 1397 落了 Prism4j 引擎 + 15 个内建语法；`vza.H` 支持集里还挂着
`vza.I` 的 11 个惰性语法（创建器在 `yia.java` 的 Function1 switch，
case 8..18：ruby/rust/bash/haskell/lua/matlab/objectivec/ocaml/php/r/racket）。
本 Phase 把这 11 个创建器逐字移植并注册，26/26 语言全量可构建——
`TextBlockOverlay` 语言选择器的全部条目（除 plaintext）从此有真实高亮。

## 原版证据

- `vza.java:10`：11 名 → yia 反射创建器（case 序号映射）。
- `yia.java`：ruby 摘 function/string + 插值自递归；rust closure-params
  inside=标点+全 token；bash 字符串内 `bash` token inside=全语法、
  $(...)/反引号按 `fhd.b` 15 名名单共享主语法 token；php `attribute`
  二段 inside、`interpolation` inside=全语法、共享 `lhd.b/c/d/e` +
  `lhd.a` 字符串组；objectivec extend(c) 摘 class-name；racket
  `nhd.b` 四段拼接 number；`e52.N3`/`oag.x2/y2` 集合拼装。

## Harmony 实现

- 11 个 `grammarX()` 创建器 + `registerCoreGrammars` 尾部注册。
- 逐字转写约定：`Pattern.compile("...", N)` → `new RegExp("...", flags)`
  （2→i、8→m、10→mi），decompiled 字符串字面量原样落盘。
- 复用件：`BASH_ENV_NAMES`、`PHP_*_SRC`（lhd）、`phpStringToken()`（lhd.a）、
  `phpNsInside()`（每处 ehd.a("inside") 新对象等价工厂）、
  `RACKET_NUMBER_SRC`（nhd.b）、`BASH_SUBSHELL_TOKENS`（fhd.b）。
- 新增 `removeCodeToken`（ruby function/string、objectivec class-name 的
  `List.remove(indexOf)` 等价）。

## 验证

- tsc 转译 + node 样例：11 语言全部产出正确类目/偏移/颜色 span；
  shell/sh/objc/rs/rb/hs 别名解析正确；`plaintext`/未知语言空 span。
- `note@default` BUILD SUCCESSFUL（CompileArkTS 无新增错误）。
- 新增 44 项断言全绿；Phase 1397 fixture 标签随更新。

## 有界差异

- bash `assign-left` 按 decompiled 逐字 `(?=\+=)`（上游为 `\+?=`，以硬证据为准）。
- `\b` 区域语义差异沿用 ADR-1333 登记。
