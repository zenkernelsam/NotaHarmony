# Phase 1111 证据 — hja/gja 持久 Map（kotlinx PersistentMap 语义）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `hja extends Map, ik6` = 不可变持久 Map

```java
interface hja extends Map, ik6 {
  gja builder();              // 瞬态 fork
  hja put(Object k, Object v); // 返回新快照（不改原图！）
}
```

`put` = persistent assoc —— 返回**新** `hja`，原快照不变。
`builder()` = 瞬态 builder 派生。

## `gja extends Map, lk6` = builder

```java
interface gja extends Map, lk6 {
  hja build();   // 冻结成快照
}
```

可变 builder → `build()` 冻结为 `hja`。`iwc`/`gja` 等处
`bxc.h.builder()` = 从快照派生 builder 进入一轮修改。

## 语义 = kotlinx.collections.immutable.PersistentMap

- `put` → 新持久 map（结构共享）。
- `builder()` → 可变瞬态。
- `builder.build()` → 冻结。

`ik6`/`lk6` = 快照/builder 标记接口。

## Harmony 决策

- ArkTS：用不可变数据结构或结构性 `Map` 拷贝 + freeze 复刻
  `put→新快照` 与 `builder→瞬态→build` 循环。
- tombstone/实体 store 皆走此持久-map 循环。

## 产出

- fixture `d02-persistent-map.mjs`（10 断言）。
- ADR-1055；中文报告。
