# Phase 1087 报告 — ija 惰性物化只读 map

## 完成内容

- `ija implements Map,ik6`：`J` 缓存 + `I`=`gja` 因果存储 +
  `e()` 物化；`get` = 缓存→物化→回填缓存。
- 只读：put/putAll/merge/computeIfPresent 抛
  UnsupportedOperationException —— 写必经 op 路径。
- `kja`/`pja` extends ija；`f(hja)` 子视图。

## 产出

- evidence `phase-1087-causal-map.md`
- fixture `d02-causal-map.mjs`（10/10）
- ADR-1031
