# Phase 976 — `hu1` Color 4B RGBA 内联结构 + ao2 required 定槽

来源：`decompiled_1.0.3/sources/defpackage/{hu1,z5c,ao2,x4d}.java`

## 1. `hu1` = Color（xwd 4B 内联结构）

```java
// toString: Color(bitsR=f(), bitsG=e(), bitsB=d(), bitsA=c())
// z5c.P 写器:
aVar.t(1,4);
u(c()); u(d()); u(e()); u(f());   // 推 A,B,G,R → 逆序落位
r();
// 线型 = {R@0, G@1, B@2, A@3} RGBA 字节序
```

- 分量类型 = `cmf`（UByte 值类）。
- ao2/rl2/td8/dm2 的 `color`/`fillColor`/`mathColor`/
  `backgroundColor` 等字段全部内联此 4B 结构——
  颜色以 **内联 RGBA** 出现（非表）。

## 2. `x4d` 定性

`x4d` = `final class implements hpd,gy4`——R8 合成
lambda（`mea` 反射引用），**非线型枚举**。Phase 912
所见 "x4d" 为 lambda 上下文误读；ao2 f1 实为
`fqa origin`（`q()` 读 c(6)）。

## 3. ao2 required 槽位对账（写侧 z(4,6,14,22)）

| 槽 | f | 字段 | 访问器 |
|----|---|------|--------|
| 4 | 0 | page:cxc | `r()` c(4) |
| 6 | 1 | origin:fqa | `q()` c(6) |
| 14 | 5 | tool/必需字段 | c(14) |
| 22 | 9 | color:hu1 | `k()` c(22) |

a() 校验串实证 "required" 字段：page/origin/color
（o14.i 消息）+ 业务约束 "Cannot create shapes with
variable width ink"、"ink_effects require a Pen or
Highlighter tool"。

## 4. 结论

- `hu1` RGBA 4B 是线型唯一颜色编码——Harmony 颜色
  字段须为 RGBA 字节序（R@0）。
- ao2 required 集 = {page, origin, f5, color}。

## 5. 验证

`d02-hu1-color.mjs` 静态断言。
