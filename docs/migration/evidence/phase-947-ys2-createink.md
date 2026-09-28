# Phase 947 证据 — `ys2.d`/`ys2.O` CreateInk 工厂+写器

## `ys2.d(...)` = CreateInk 工厂（实证）

签名：(cxc page, fqa origin, Float rotation,
qed scale, u16 tool, t16 style, ife tapePattern,
hu1 color, float width, jmf×3 paths, hu2 fillColor,
List styleMap, xgb audio, mmf duration,
List inkEffects, int mask)

```
dm2Var.d(byteBuffer position + int, bb)
ybg.c(dm2Var)          // 解析后校验驱动
```

`w71` = jmf 的 ByteBuffer 实现（`f(bb)` 直接给
/`e()` 计算/`h(i)` 逐字节）。

## `ys2.O(builder, ...)` = CreateInk 写器（实证）

```
路径×3: jmf → k(bb) / D(1,len,1)+b(byte) 逐字节向量
styleMap: D(20,len,4) + zwd.a((xwd)ix4.invoke(i))
          // zwd = inline-struct 写器分发
C(20)                       // 20 槽
h(9/10/11, pathVec×3)       // f9-11 三路径
h(13, styleMapVec)          // f13 styleMap
f(18, rz1.h0)               // f18 inkEffects
a(19, rz1.g0, true)         // f19 tinted 默认 true
j(0, nti.X)  j(1, apb.Y)    // f0 cxc, f1 fqa
d(2, rot, 0.0)              // f2 rotation
j(3, apb.Z)                 // f3 scale qed
c(4, u16.I,0) c(5,t16.I,0) c(6,ife.I,0)
                          // f4-f6 枚举
```

## 写器辅助登记

`apb.Y`=fqa、`apb.Z`=qed、`nti.X`=cxc、
`z5c.P`=hu1、`zwd.a`=inline-struct 分发、
`rz1.h0/g0`=位集编码、`w71`=ByteBuffer jmf。

## 结论

CreateInk 工厂+写器钉死——路径=1 字节
向量语义终证；styleMap 经 zwd 分发。
