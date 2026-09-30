# Phase 1131 证据 — e4c.g 锚点插入算法 + e4c 公共 API

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `e4c` 公共 API

- `b(uq9)→i4c` 应用 op；`a()→m4c` spec；`c()→int` 长度。
- `d()→nr5` 布局引擎；`getText()→jxc` 文本视图。
- `o(exc)→Integer` 锚→位、`w(int)→exc` 位→锚、`y(cxc)→Integer` 页→位。
- `g(mr5,exc,m3c,boolean)→d4c` = **锚点插入**。

## `e4c.g` 插入算法

```java
mnb/knb out-param;  njj.t(iwc, anchor, rwc, cb)  树遍
knb.I = numY - s3c.e;                  // 分裂偏移
else mr5Var→k4c.a() → s3c.f 锚; knb=0; njj.t(...)
if (knb < 0) a.c(log "span cache split offset negative") + k4c.e=true
if (i <= s3c.i):
  n4c.a(s3c.c, i)                      // 码点→索引
  charSeq.subSequence                  // 切段
  njj.L(iwc, qwc.d(hr5)) tombstone?    // 删节点跳过
    njj.t(..., zm7 find-next-non-deleted) → excD = swc.d(hr5)
  new s3c{charSeq, e+knb, exc, excD, k3c.a, prev}  // 新段
```

`knb`/`mnb` = `I` 字段出参 holder；`njj.t` = 锚点树遍历（回调
`wc`/`zm7` 找位置/下个未删节点）；`d4c` = 插入结果标记接口。

## Harmony 决策

- 插入 = 锚定位→span 分裂（码点切）→tombstone 跳过→
  新段构建；`d4c` 结果标记。
- `nr5` 布局引擎 + `jxc` 文本视图直移。

## 产出

- fixture `d02-insert.mjs`（10 断言）。
- ADR-1075；中文报告。
