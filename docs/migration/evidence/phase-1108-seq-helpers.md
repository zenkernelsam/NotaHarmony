# Phase 1108 证据 — njj.L/M/y 序列辅助 + xj2.f/g 解码 + njj.z

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `njj.L(jxc, exc)` = 锚点成员判定

```java
jxc.a() ? ba6.o(jxc.f().get(exc), Boolean.TRUE)
        : jxc.b().contains(exc)
```

`jxc` = 双模式 union：`a()`=map 模式（值==TRUE 判定）/
`b()`=set 模式（contains）。tombstone/存在性统一入口。

## `njj.M(float[])` = 恒等矩阵判定

`len>=16 && m[0]=1,m[1..3]=0,m[5]=1,…,m[15]=1` ——
`y18` 4×4 矩阵是否恒等（变换短路优化）。

## `njj.y(jxc, exc)→Integer` = `x(jxc, Q(jxc,exc))` 位序链

`Q` 查节点、`x` 取位序 → 锚点→位置。

## `xj2.f(obj, Map)` = tombstone 值解包

`map.get(obj)`；`bl2` 实例 → `.c` —— tombstone 条目是
`bl2` 包装的值。

## `xj2.g(fzf, hw6)` = long-打包 float 对解码

`(K(0L) >> 32)` + `intBitsToFloat` —— 与 Phase-1099 `rh8.a`
打包互逆（高32位float1/低32位float2）。

## `njj.z(s7c)→long` = SQLite `last_insert_rowid()`

`D1("SELECT last_insert_rowid()")` + `x1()` + `getLong(0)`
+ `rh8.q` close —— Room 插入后取 rowid。

## Harmony 决策

- `jxc` union 成员判定 + bl2 解包直移。
- float 对 long 打包/解包与 rh8.a 配对实现。
- `last_insert_rowid` → Harmony 关系型 DB 对应 API。

## 产出

- fixture `d02-seq-helpers.mjs`（10 断言）。
- ADR-1052；中文报告。
