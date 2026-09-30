# Phase 1122 证据 — v69.b() note 物化（live→snapshot MVCC）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `v69(a79, boolean, ny3)` = 活 note 应用态

包装 `a79` + `ny3` bounds 服务 + 全部 `yc6` 寄存器 + map 集合。

## `v69.b() → a79` = note 物化

```java
if (s == a79.g) return a79;          // 版本一致 → 复用（dirty-check）

// jm5 d = dirty-block 状态 {f1a c, ko d}
ko {rvb M, iwc J, al2 K, xgb L}
  iwc.c() → bxc;                     // live 文本序列→spec
  al2.a() → cl2;                     // tombstone→惰性 map
  xgb L;                             // 时戳
→ new rvb(bxc, cl2, xgb)             // 文本块快照

ria.h → bka 列表; 迭代 bq3/uy5 槽:
  wz9 build() → bka.set(i,…)         // 每槽物化
bka.f() → z4 冻结 → q07(z4)          // 持久列表包装

lia.e()→kia; nja.a()→oja
→ new f1a(a, rvb, cl2, kia, oja, q07, jm5.b)   // 页/块快照
→ new a79(...)                                        // 新 note
```

## MVCC 循环

live builders（`iwc`/`al2`/`ria`/`bka`）→ frozen specs
（`bxc`/`cl2`/`z4`/`kia`/`oja`）→ `f1a` 页快照 → `a79` note。

- `s==g` = 版本戳短路（无脏则复用原 note）。
- `rvb`/`f1a`/`q07` = 页/块快照类型。

## Harmony 决策

- 版本戳 dirty-check + builder→snapshot 级联物化。
- 快照类型直移（rvb/f1a/q07/bka/z4/kia/oja）。

## 产出

- fixture `d02-note-materialize.mjs`（10 断言）。
- ADR-1066；中文报告。
