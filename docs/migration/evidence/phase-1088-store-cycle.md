# Phase 1088 证据 — gja↔hja 因果存储 builder↔快照环

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 因果存储双层（呼应实体 build↔builder 环）

```java
gja extends Map, lk6      // 可写因果存储（builder 侧）
    hja build();

hja extends Map, ik6      // 不可变存储快照（spec 侧）
    gja builder();
    hja put(k,v);         // 协变 put
```

- `ija.I` = `gja`（活存储），`ija.f(hja)` 子视图接 `hja`。
- `lk6`/`ik6` = Kotlin mutable/immutable 集合标记接口。

## 完整集合栈

```
v69（文档根）
  └ ija 只读物化视图（J 缓存 + e()）
       └ I: gja 活因果存储（builder）
            └ build() → hja 不可变快照
```

写路径：op → gja（builder）；读路径：ija 视图 / hja 快照。

## Harmony 决策

- 因果存储 = builder(gja)↔快照(hja) 环，与实体层同构。
- 只读视图(ija) + 可写存储(gja) + 不可变快照(hja) 三层。

## 产出

- fixture `d02-store-cycle.mjs`（10 断言）。
- ADR-1032；中文报告。
