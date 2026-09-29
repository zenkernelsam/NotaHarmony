# Phase 1032 证据 — cu9 manifest 索引写器

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `cu9` = manifest 索引写器

```java
for (zz e : a00.b()) {          // 分区1
    jqe j = boh.a(e.b, e.c, i2, i3, len, true);   // dir=true
    yzVar.e((gnd)e.a, (int)(j.a>>32),
            (int)(j.a & 0xFFFFFFFF));
}
for (zz e : a00.a(0, len)) {    // 分区2
    jqe j = boh.a(e.b, e.c, i2, i3, len, false);
    // ug7 → tg7 → yzVar.b(tg7, off, len)
    // ug7 → sg7 → yzVar.a(sg7, off, len)
}
for (zz e : a00.c(len)) {       // 分区3
    jqe j = boh.a(e.b, e.c, i2, i3, len, false);
    yzVar.c(e.d /*name*/, (String)e.a, off, len);
}
```

## 关键发现

- `boh.a` 返回 `jqe`——`jqe.a` = **packed long**
  `{offset<<32 | length}`——条目偏移/长度打包。
- `yzVar` = manifest 写器（`e`/`b`/`a`/`c` = 四类
  条目写入）——目录/asset/嵌套/命名键值。
- `a00` = 条目容器三分区：`b()`/`a(0,len)`/`c(len)`
  ——目录段/资产段/键值段。
- `zz` = 条目 `{a=handler, b, c, d=name}`。
- `ug7`/`tg7`/`sg7`/`gnd` = 条目 handler 类型。

## HarmonyOS 决策

- manifest 索引结构保留（offset/length 打包进
  manifest 条目）；zip 容器段布局对齐。

## 产出

- fixture `d02-manifest-index.mjs`（10 断言）。
- ADR-0976；中文报告。
