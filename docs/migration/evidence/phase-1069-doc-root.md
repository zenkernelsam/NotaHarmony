# Phase 1069 证据 — v69 文档根 + *ja/*ia 因果集合族

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `v69` = 文档/页 CRDT 根

```java
{a79 a, boolean b, ny3 c, jm5 d, e4c e(实体集), yc6 f,
 pja/kja/gja/aja×3/tia g..n, al2 o, kja p, lia q,
 Set r, int s, Map t, List u, fqb v..C (7 元数据寄存器),
 qja D, bja E/F, uia G}
```

## `*ja`/`*ia` = 因果集合族（CRDT 容器基类）

| 基类 | 形状 |
|------|------|
| `via` | `LinkedHashMap K` —— 因果有序 map |
| `ija` | `implements Map,ik6` + `LinkedHashMap J` |
| `jja` | ija 系（qja extends jja） |
| `vz` | 集合基（bja/uia extends vz） |
| `w4` | `extends AbstractSet` —— CRDT set |

族成员：`aja,bja(vz),gja,kja(ija),lia(w4),pja(ija),qja(jja),tia(via),uia(vz)`

## Harmony 决策

- 文档根持实体集 + 元数据寄存器 + 因果集合。
- 集合族 = LinkedHashMap/AbstractSet 基的因果序容器。

## 产出

- fixture `d02-doc-root.mjs`（10 断言）。
- ADR-1013；中文报告。
