# Phase 946 证据 — `o0j.f` ModifyInk 写器

## 写端序列（实证）

```
D(8, len, 4)          // inks 向量 elemSize 4 (qo5)
xd8.f/e → k()         // 三路径字节向量预编码
D(20, len, 4)         // styleMap 元素向量
C(19)                 // 19 槽表
h(0, inksVec)         // f0: inks qo5[]
j(1, nti.X)           // f1: page cxc
j(2, apb.Y)           // f2: origin fqa（apb.Y=点写器）
h(3, r7=k2d)          // f3: rotation SetFloat
h(4, r8=y2d)          // f4: scale SetSize
l=true; c(5,t16.I,0); l=false   // f5: style 枚举强制写
j(6, z5c.P)           // f6: color hu1（z5c.P=色写器）
d(7, width, 0.0)      // f7: width float
h(8/9/10, path×3)     // f8-10: encodedCenter/Custom/FillPath
h(11, g2d)            // f11: fillColor SetColor
h(12, styleMapVec)    // f12: styleMap 向量
f(13, tmf.I)          // f13: zIndex ULong
c(16, ife.I, 0)       // f16: tapePattern（l=true 强制）
f(17, rz1.h0)         // f17: inkEffects long 位集
a(18, rz1.g0, false)  // f18: tinted bool
n(); z(iN, 4)         // required f0: inks 向量必需
```

## 关键机制

- `aVar.l = true/false` = **枚举强制写开关**——
  byte 枚举即使=默认 0 也须写出（vtable 标记
  存在），防"缺省=未设"歧义。
- `xd8` = 路径 provider lambda（ByteBuffer 直接
  `f(bb)` 或 `e()` 计算）。
- `rz1.h0/g0` = 位集→long / bool 编码助手。
- `z(iN,4)` = **f0 inks 向量 required**——ModifyInk
  唯一必需字段。

## 与读端对称（910）

f0-f18 逐项镜像读端 c(4)-c(40)。

## 结论

ModifyInk 写端 19 槽钉死；枚举强制写机制 +
f0 required 确认。
