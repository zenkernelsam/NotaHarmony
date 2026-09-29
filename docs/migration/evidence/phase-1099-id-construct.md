# Phase 1099 证据 — rh8.b opId 构造管线 + rh8.a 浮点打包

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `rh8.b(int i, short s) → qo5` = opId 构造（完整管线）

```java
qo5 qo5 = new qo5();
c8d c8d = new c8d();
a buf = dk4.a(c8d);                  // builder 池取
buf.t(4,8); buf.w(i); buf.s(2); buf.y(s); buf.p(r());
                                     // 写 8B {d,c} struct
ByteBuffer bb = wrap(buf.A()) LITTLE_ENDIAN;
qo5.b(bb.getInt(pos)+pos, bb);       // 绑进 qo5
ybg.c(qo5);                          // 校验
q(c8d, null);                        // 回收 builder
return qo5;
```

- opId = 经真 FlatBuffers 写→绑→校验→回收构造。
- `dk4.a`/`c8d` = builder 池；`qo5.b` = 缓冲绑定。

## `rh8.a(float, float) → long` = 坐标打包

```java
(bits(f2) & 0xffffffff) | (bits(f1) << 32)
```

两 float 打包成一个 long（点/尺寸→long 键，空间索引用）。

## `au1.c1(List)` = `List.first()`（gxc 锚点取首元素）

## Harmony 决策

- opId = FlatBuffers write→bind→validate 构造；builder 池化。
- float 对打包 long 键。

## 产出

- fixture `d02-id-construct.mjs`（10 断言）。
- ADR-1043；中文报告。
