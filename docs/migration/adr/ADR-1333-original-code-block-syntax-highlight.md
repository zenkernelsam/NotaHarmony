# ADR-1333 — 代码块语法高亮（Prism4j 引擎 + 核心语法集）

- 状态：已接受
- 日期：2026-08（Phase 1397）
- 证据：`docs/migration/evidence/phase-1397-original-code-block-syntax-highlight.md`

## 决策

把原版 `io.noties.prism4j` 分词引擎与渲染接线完整移植进
`CodeSyntaxHighlighter.ets`：CODE_BLOCK 段落按 `programmingLanguage`
惰性构建语法、分词、递归提取 span，仅以 `foregroundColor` 覆盖到
渲染期字形样式数组（与原版 `o3i.c`/`uog` 同语义），不触碰持久化
`characterStyleRuns`。

## 实现要点

- 引擎层逐函数对应上游 `Prism4j.matchGrammar`：greedy 区域匹配、
  oneShot 递归（`target` token 截断）、lookbehind=捕获组 1 前缀截除、
  `SyntaxImpl.tokenized=hasInside`、deleteCount≠1 时重跑更早 token。
- `rgm` 派生（extend/过滤 extend/insertBefore 路径/findToken/insideOf）
  + `c9n` identity 深拷贝——csharp/kotlin/c/go/cpp/java/swift/javascript/
  markdown 的派生链与原版同构。
- markup 热切 javascript/css 的互注（`<script>`/`<style>` 内按语言着色）
  保留原版时序：markup 入缓存后再热切。
- 调色板逐位照抄 `o3i.b`：16 个 bni 类目 → ARGB（GitHub-light 系）。
- `vza.h` 别名 + `vza.H` 26 名支持集原样；`ynh.d` 门控语义=
  `SUPPORTED_CODE_LANGS` 判定。

## 渲染接线

`applyCodeBlockFace` 签名 `length:number` → `characters:string[]`：
先照旧处理等宽面，再按 `\n` 切段对 CODE_BLOCK 段落求
`codeBlockHighlightSpans` 并逐字符覆 `foregroundColor`。measure/layout/
render/hit 五处调用点不变——度量与绘制看到同一套颜色覆盖，与原版
`o3i.a` 在 `AnnotatedString` 构建期注入一致。

## 行为差异

1. **惰性语法集（11 语言）本 Phase 未注册创建器**——rust/bash/php 等
   段落先按纯等宽渲染（原版 `chdVarB==null` 时同此视觉），Phase 1398
   补齐 `yia.java` 对应创建器后自动生效，无需再改接线。
2. Java `Matcher.region` 的 `\b` 能看到区域起点前字符，JS `substring`
   等价写法失去该上文；现存语法中无 `\b` 引导的贪心 pattern 依赖此边界，
   登记为可接受近似。
3. 原版 `uog` 掩码只设 color——移植侧 `codeStyle.foregroundColor = color`
   等价；字符自带 run 的 bold/italic/fontSize 等属性保留，语义一致。

## 回归

- 新增 `d02-original-code-block-syntax-highlight.mjs`（59 项结构断言：
  引擎关键语义、派生工具、类目映射、调色板、别名、注册表、渲染接线）。
- 功能自验（tsc 转译 + node 跑样例）：15 语言全部产出正确类目 span，
  typescript 别名生效，未支持语言空 span。
- `d02-original-quote-code-blocks.mjs` 的 `applyCodeBlockFace` 断言按新签名
  （`characters` 形参）更新。
