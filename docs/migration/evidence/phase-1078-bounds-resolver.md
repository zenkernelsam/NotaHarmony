# Phase 1078 证据 — ba6.k 包围盒解析器 + sia/vnd 空间索引

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ba6.k(qo5 id, Map×7, ue4) → k11` = 实体包围盒解析

```java
// ① 空间缓存快路径
vnd = ((sia)ue4.J).a.h( (lt&0xffffffff)<<32 | (site&0xffff) );
if vnd → vnd.b(vnd) bounds 直接返回;

// ② 变换路径
be5 e = R(id, map..map5, true, false);      // 解析实体
bmb crop = do6.i(e.i(), map7);             // 页裁剪框
return h0(e.G(), crop.c());                // 变换包围×裁剪
```

## 空间索引键 = **packed opId long**

`(logicalTime & 0xffffffff) << 32 | (site & 0xffff)` ——
把 qo5{site:short, lt:int} 打包成一个 long 作空间/缓存键
（`sia`/`vnd` = R-tree/网格索引，`vnd.b` 取包围盒）。

## `ba6.R(qo5, map×5, bool, bool)` = 实体→be5 解析器

7-map 版本退化为 5-map + `ue4`；`K(qo5,map2)` 旁路。

## Harmony 决策

- 包围盒解析 = 空间索引缓存 → transform×crop。
- opId 打包成 long 作索引键（无符号 lt 高位 + site 低位）。

## 产出

- fixture `d02-bounds-resolver.mjs`（10 断言）。
- ADR-1022；中文报告。
