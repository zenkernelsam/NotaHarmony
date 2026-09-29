# Phase 1110 证据 — iwc 文本序列 CRDT 活实例 + y51 长键查找

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `iwc implements jxc` = 文本序列活 CRDT（续 Phase 1109）

```java
iwc(bxc spec) {
  bxc.c.a() → wia d;          // 实体 store
  new y51(wia) → y51 e;       // 长键查找
  bxc.d.g() → bka f;          // collection 视图
  bxc.b→k5c → g5c g;          // 持久列表
  bxc.h.builder() → gja i;    // 因果 builder #1
  bxc.g.builder() → gja k;    // 因果 builder #2
  al2 l;                      // tombstone
  xgb q;                      // 时戳
  hr5 t/u/v/w;                // 锚点×4
}
```

`bxc` = 文本序列 spec；`iwc` = live —— 与 `qy0(ry0)`/`m5d(n5d)`
同一 spec→live 对称。

## `y51 extends g8d` = 长键查找适配器

`a(long j) → f8d = wia.c.h(j)` —— 把 `wia` 的 `igf` long-map
适配成 `g8d`/`f8d` 查找接口。

## `bxc implements jxc, bf0` = 文本序列 spec 也是锚集合

spec 自身实现 `jxc`（锚集合）+ `bf0`（spec 标记）。

## `bka extends u4 implements Collection` / `g5c extends y3`

集合视图 / 持久列表变体。

## Harmony 决策

- 文本序列 spec(bxc)→live(iwc) 同 spec→live 对称；双 gja
  builder = 两集合并行构建。
- 长键查找适配 = map.get → 视图接口。

## 产出

- fixture `d02-iwc-live.mjs`（10 断言）。
- ADR-1054；中文报告。
