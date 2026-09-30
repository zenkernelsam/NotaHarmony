# Phase 1124 证据 — ija 惰性物化因果 map 完整语义

来源：`C:\Users\Cisco He\Desktop/Notability/decompiled_1.0.3`

## `ija implements Map,ik6` = 惰性物化 map

```java
ija { gja I;              // 因果 builder（写入目标）
      LinkedHashMap J }   // 物化 memo 缓存

get(obj):
  J.get(obj) → 命中直返；
  I.get(obj) → e(obj3) 变换 → J.put(obj, e) 缓存 → 返。
                              // 首读物化 + memo

d(obj, v):                    // 写
  J.remove(obj);              // 失效 memo
  I.put(obj, v);              // 写进 builder
  c();                        // 钩子（派生缓存失效）

a() → jja:                    // 快照
  J.forEach(flush);           // 物化缓存冲掉
  f(I.build())                // gja 冻结 + f(hja) 快照工厂
```

- `b(obj)`/`e(obj)`/`f(hja)` 抽象 = 子类特化
  （kja→`b()`、nja→`e()`+`f()`）。
- `c()` = 空钩子（子类覆写清派生缓存）。

## 模式

写 → builder（`I.put`）；读 → memo 惰性物化（`e()`）；
快照 → `I.build()` + `f()` 工厂。**写穿 + 懒读缓存 +
冻结物化**三合一。

## Harmony 决策

- 惰性物化 map = 写穿 builder + 读 memo + 快照工厂；
  Harmony 用 pending-Map + lazy-getter + freeze 复刻。

## 产出

- fixture `d02-ija-lazy.mjs`（10 断言）。
- ADR-1068；中文报告。
