# Phase 974 — 结构写器尾部：xq3/vy7/ukb/ua0

来源：`decompiled_1.0.3/sources/defpackage/{vfj,fsi,ddj,aa6,vy7}.java`

## 1. `vfj.d(xq3)` = DuplicateOp 24B

```java
t(8,24);
x(jC);                 // duplicateServerTime → +16
x(jE);                 // originalServerTime → +8
t(4,8); w(iD); s(2); y(sC);   // qo5 opId → +0..7
r();
```

`{opId:qo5@0, originalServerTime:long@8,
duplicateServerTime:long@16}` — 与 950 读侧镜像。

## 2. `fsi.b0(vy7)` = Margins 16B

```java
t(4,16); v(e); v(d); v(c); v(f);
// 推序 e,d,c,f → f@0,c@4,d@8,e@12
```

toString 对应：`Margins(top=f@0, bottom=c@4,
left=d@8, right=e@12)`——**线序 {top,bottom,left,right}**。
`ddg.l(name,v)` = 逐字段负值校验（"Margins cannot be
negative"）。

## 3. `ddj.b(ukb)` = RecordingSegment 16B

```java
t(8,16); x(c); x(d);   // c@0=start, d@8=end
```

## 4. `aa6.x0(ua0)` = AssetHash 64B

```java
t(8,64); x(j); x(i); x(h); x(g); x(f); x(e); x(d); x(c);
// c@0,d@8,e@16,f@24,g@32,h@40,i@48,j@56
```

8×long 逆序推 → `{bits0..7 @0..56}`，与 967 读侧
`getLong(I+0..56)` 逐字节镜像。

## 5. 结论

**z0c(21) 结构注册表 15 项写器全证**：qo5(rh8.O)、
cxc(nti.X/sg5.f)、xq3(vfj.d)、utf(wtf.b)、v01(rz1.b0)、
fqa(apb.Y)、qed(apb.Z)、bmb(ldj.A2)、vy7(fsi.b0)、
ukb(ddj.b)、ua0(aa6.x0)、cwb(efj.b)、hd1(y5j.c)、
xq3/v01 等——写↔读字节对称全线关闭。

## 6. 验证

`d02-struct-writer-tail.mjs` 静态断言。
