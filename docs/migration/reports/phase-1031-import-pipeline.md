# Phase 1031 报告 — 导入管线

## 范围

`boh` 三面 + `zb5` 接口 + `gg1`/`qma` 包导入 +
`cu9` manifest 校验。纯审计。

## 原版发现

- `boh`：a() 条目校验/c(File)→conf 串/d() unzip。
- `zb5` 导入器接口 `{b,c,d,e}`；`gg1`/`qma` impl
  ——unzip+conf 读+`dc5Var` pack 缓存（手写包）。
- `cu9` 三次 `boh.a` manifest 校验。

## Harmony 决策

包导入等价；手写包分发 fail-closed。

## 产出

- 证据：`phase-1031-import-pipeline.md`
- Fixture：`d02-import-pipeline.mjs`（10/10）
- ADR-0975；全量 Replay 见本提交。
