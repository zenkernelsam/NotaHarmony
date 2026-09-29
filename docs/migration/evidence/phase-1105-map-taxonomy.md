# Phase 1105 证据 — v69 实体-map `*ja`/`*ia` 完整谱系

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## builder 侧（`via` 子类）

- `aja extends via implements Map,ik6` —— `b(obj)` 直通值变换。
- `tia extends via implements Map,ik6` —— 同上。

## 快照侧（`vz` 子类）

- `bja extends vz implements Map,ik6`：
  **`W0(wia)→via`** = 快照→builder 派生（新 store 绑定，copy-on-write
  fork —— snapshot→builder→mutate→snapshot 的 MVCC 循环）。
- `uia extends vz implements Map,ik6` —— 只读快照。

## hja-backed 只读 Map

- `jja implements Map,ik6`：包装 `hja`（Phase-1088 因果 store 快照）；
  clear/put 等 mutator 抛 `UnsupportedOperationException`。
- `qja extends jja` —— v69 `r()` 实体 store 的只读 Map 视图。

## v69 七类 store 归位

`i()→uia`、`k()/n()→aja`、`l()/p()→bja`、`r()→qja` —
builder/snapshot 两类按可变域分工。

## Harmony 决策

- 实体 map = builder（pending map）↔ snapshot（只读）双向；
  hja 因果 store 上叠只读 Map 视图。
- MVCC：改 = 快照派生 builder → 写 pending → `a()` 物化新快照。

## 产出

- fixture `d02-map-taxonomy.mjs`（10 断言）。
- ADR-1049；中文报告。
