# Phase 1143 证据 — v69.a 资产索引写 + za0/ua0/qa0

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `v69.a(pa0, List)`

```java
if (pa0==null) return;
ua0 ua = pa0.a().j();                    // pa0→资产哈希键
za0 za = h().get(ua);                    // h()=gja 注解图
h().put(ua, za!=null
  ? za0.a(za, ys2.J(za.b, list), 1)      // 并入 list→set
  : new za0(qa0.I, au1.X1(list)));       // 新建{type,set}
```

资产/附件索引写：`pa0`（附件 ref）→`ua0` 资产键→`gja`
注解图 `h()`→`za0` 条（新建或 copy-with 并入 list）。

## 类型

- `pa0` = 附件 ref 接口（`a()`→载体 `.j()→ua0`）。
- `ua0 extends xwd implements ka4` = FlatBuffers 资产哈希
  表（`a()→String` + `c/d/e()→long`）。
- `za0{qa0 type, Set b}` = 注解条；`a(za0,set,i)` copy-with。
- `qa0` = 注解类型 enum。
- `ys2.J(set,list)` = set+list 并；`au1.X1(list)`=toSet。

## `v69.w(coll, ff2)→Object` = suspend 委托

`t69` 状态机 → `x(collection, t69)` —— w 委托 x 的收集
挂起辅助。

## 语义

`a` = 资产→实体引用索引（哪些 op/实体引用哪个资产），
写 `gja` 注解图；`w/x` = 挂起收集辅助。

## Harmony 决策

- 资产索引 = assetHash→`{type,Set}` 注解图写；
  `za0` copy-with 并入。
- Harmony：Map<hash,{type,Set}> + copy-with。

## 产出

- fixture `d02-asset-index.mjs`（10 断言）。
- ADR-1087；中文报告。
