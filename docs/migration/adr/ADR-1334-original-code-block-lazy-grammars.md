# ADR-1334 — 代码块语法高亮：11 个惰性语法注册（vza.I）

- 状态：已接受
- 日期：2026-08（Phase 1398）
- 证据：`docs/migration/evidence/phase-1398-original-code-block-lazy-grammars.md`
- 前置：ADR-1333（引擎 + 15 内建语法 + 渲染接线）

## 决策

把 `vza.I` 对应 `yia.java` 的 11 个延迟语法创建器（ruby/rust/bash/haskell/
lua/matlab/objectivec/ocaml/php/r/racket）逐字移植进
`CodeSyntaxHighlighter.ets` 并注册——`vza.H` 26 名支持集自此全量可构建。

## 实现要点

- 逐字转写约定：decompiled `Pattern.compile("...", N)` 字符串字面量原样进
  `new RegExp("...", flags)`（2→i、8→m、10→mi），避免二次转义误差。
- 结构件忠实移植：ruby 的 extend(clike)+摘除+四处 insertBefore+插值自递归；
  rust 的 closure-params inside=自身标点+全 token；bash 的字符串内命令行
  inside=全语法、$(...) 按 fhd.b 名单共享复用主语法 token；php 的
  attribute 二段 inside、interpolation 自递归、lhd 四静态 + lhd.a 字符串组；
  objectivec 的 extend(c)+摘 class-name；racket 的 nhd.b 四段拼接 number。
- 新增 `removeCodeToken`（等价 `List.remove(indexOf(name))`，找不到即跳过）。

## 行为差异

1. bash `assign-left` 按 decompiled 逐字 `(?=\+=)` 移植（上游 prism-bash 为
   `\+?=`，JADX 可能吞了 `?`；按硬证据为准登记）。
2. `\b` 区域语义差异同 ADR-1333。

## 回归

- 新增 `d02-original-code-block-syntax-highlight-lazy.mjs`（44 项断言）。
- `d02-original-code-block-syntax-highlight.mjs` 的 vza.H 注释同步更新。
- 功能自验：11 语言 + 6 别名全部产出正确 span；`note@default` 绿。
