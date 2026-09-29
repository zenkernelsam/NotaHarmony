# Phase 1076 证据 — u09 六元 id 联合 + fsi.D/E 解构器

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `u09` = 六变体 id 联合

| 变体 | 载荷 | 语义 |
|------|------|------|
| `o09` | `qo5 b` | 实体 id |
| `r09` | `cxc b` | 页 id |
| `p09` | `qo5 b` + `a()` | 另一 opId 引用 |
| `t09` | `qo5 b` | 删除/tombstone 引用 |
| `q09` | （无） | unit 占位 |
| `s09` | `ua0 b` | **asset-hash（SHA-512）引用** |

`tz9{cxc a}` = 页引用包装（E() 产物元素）。

## `fsi.D(uq9)` = 实体 id 提取

```java
for u09 in F(op):
    o09 → b;  p09 → a();  t09/r09/q09/s09 → null(跳过)
    else o14.t()                            // unreachable
```

## `fsi.E(uq9)` = 页 id 提取

`r09 → b → tz9`；其余 null。

## Harmony 决策

- `u09` = 六变体 sealed；`s09` 把 asset-hash 纳入引用域。
- D/E 按变体解构出 qo5/cxc 集。

## 产出

- fixture `d02-u09-union.mjs`（10 断言）。
- ADR-1020；中文报告。
