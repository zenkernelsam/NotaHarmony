# Phase 1109 证据 — jxc 锚集合 union + bl2 tombstone 条目 + iwc 活锚 store

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `jxc` = 锚点集合 union 接口

```java
interface jxc { Set b(); Map d(); Map f(); Map h(); }
```

`njj.L` 的 `a()`/`b()` 分派即此 union 双模式（map 值判定 / set 包含）。

## `bl2` = tombstone 条目

```java
class bl2 { qo5 a;   // 删除 opId
            Object b; // 键（锚点）
            Object c } // 值
```

`xj2.f(map.get(obj))` 返回 `.c` —— tombstone map 存 `bl2` 包装值。

## `iwc implements jxc` = e4c 的活锚点 store

```java
iwc { bxc b; boolean c; wia d;   // 实体 store（Phase 1102）
      y51 e; bka f; g5c g;
      LinkedHashMap h;           // pending
      gja i }                    // 因果 builder（Phase 1088）
```

文本序列锚点索引 = `wia` 空间 store + `gja` 因果 builder +
LinkedHashMap pending —— e4c `e` 字段。

## 数据流

op 锚点 → `iwc`（jxc union）→ `njj.L/N/O/y` 查询 →
`xj2.f` 解包 bl2 判定 tombstone → `gja` 物化新快照。

## Harmony 决策

- 锚集合 union = Set|Map 双模式；tombstone = `{opId,key,value}`。
- 活锚 store = 空间索引 + 因果 builder + pending map。

## 产出

- fixture `d02-anchor-store.mjs`（10 断言）。
- ADR-1053；中文报告。
