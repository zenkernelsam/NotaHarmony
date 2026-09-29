# Phase 1008 报告 — 查询构造器

## 范围

e6c.a/b、mlc 五模式、m2a 前缀变换。纯审计。

## 原版发现

- `e6c.a`：LIKE 模式 = 折叠 + `\`/`%`/`_` 转义 +
  `%…%`（配 `ESCAPE '\'`）。
- `e6c.b`：FTS MATCH 串 = `[^\p{L}\p{N}]+` 分词去空；
  SUBSTRING→null 走 LIKE；WHOLE_WORD→空格并；
  EXACT→引号短语；PREFIX/TOKEN_PREFIX→`token*`。
- `m2a` case23 = `concat("*")`。

## Harmony 决策

LIKE 等价；FTS 模式语义保留（应用层模拟）。

## 产出

- 证据：`phase-1008-query-builder.md`
- Fixture：`d02-query-builder.mjs`（14/14）
- ADR-0952；全量 Replay 见本提交。
