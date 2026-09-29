# Phase 1090 证据 — e4c 文本容器（exc 锚序列 + UTF-8 解码）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `e4c implements o4c` = 文本块内容容器

修正 Phase 1066：`e4c` 不是组成员集合，是**文本块宿主**。

```java
{ArrayList c, k4c d, iwc e, gja f, al2 g, int h, ...}
exc anchor = au1.c1(gxc);               // 锚点反序列化
s3c(set2, set3, mz0, p, i, exc, hr5);   // 文本片段
swc.d(hr5)                              // 锚点导航
UTF-8 CharsetDecoder (malformed/unmappable → REPORT)
char[8192] decode buffer                // 流式解码
m4c.D(b, m, n, h, arrayList, l4c, bxc, f.build(), g.a(), 4225)
                                        // copy-with 物化
```

- `q = rh8.b(-1,0)` 哨兵 opId（1066 已录）。
- 持 UTF-8 `CharsetDecoder`（REPORT 非法/不可映射）——
  文本以 UTF-8 字节流存，decode 物化。
- `exc`/`s3c`/`hr5`/`swc`/`gxc`/`iwc`/`mz0`/`qw3` = 文本序列类型。

## Harmony 决策

- 文本块 = `e4c`（exc 锚点序列 + UTF-8 流解码 +
  m4c copy）。

## 产出

- fixture `d02-text-container.mjs`（10 断言）。
- ADR-1034；中文报告。
