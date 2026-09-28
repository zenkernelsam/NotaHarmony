# Phase 969 — 内联结构写器字节序终证（wtf/rz1/apb/y5j/efj）

来源：`decompiled_1.0.3/sources/defpackage/{wtf,rz1,apb,y5j,efj}.java`

FlatBuffers builder 自底向上构造：写器**逆序推字段**，
先推者居高位。以下逐一与读侧布局核对。

## 1. `wtf.b` = utf Uuid 16B

```java
t(8,16);            // 16B 对齐 8
x(c());             // bitsLow → +8
x(d());             // bitsHigh → +0
r();
```

线型 `{bitsHigh@0, bitsLow@8}` — 与 utf 读侧镜像；
`wtf.e(utf)` = uuid 全零判定（`ttf.K` 常量）。

## 2. `rz1.b0` = v01 Boundary 16B

```java
t(4,16);
s(3);               // pad 3 → @13..15
u(b2);              // y01 boundaryType byte → @12
t(4,12);            // 内嵌 cxc
w(iC);              // index → +8
w(iD);              // timestamp → +4
s(2);               // pad → @2..3
y(sC);              // site → +0
```

线型 `{site:u16@0, pad@2, ts:u32@4, idx:u32@8,
boundType:u8@12, pad@13..15}` — 与 v01 读侧
`{cxc@0, y01@12}` 完全镜像。

## 3. `apb.Z` = qed Size 8B

```java
t(4,8); v(c()); v(d());
// → c()@0? 逆推：d() 后推居低位… 实测 d=width@0
```

推序 c→d，d 落 +0：`{width@0, height@4}` 与读侧一致。

## 4. `y5j.c` = hd1 CanvasAnchor 20B

```java
t(4,20);
  t(4,8); v(fD); v(fC);        // fqa @+12..19
  t(4,12); w(idx); w(ts); s(2); y(site);  // cxc @+0..11
```

线型 `{page:cxc@0, origin:fqa@12}` — 读侧镜像 ✓。

## 5. `efj.b` = cwb ReplyAnchor 8B

```java
t(4,8);
  t(4,8); w(ts); s(2); y(site);  // qo5 = {site@0, ts@4}
```

## 6. 结论

**内联结构写↔读字节对称全部实证**：qo5/cxc/v01/utf/
fqa/qed/hd1/cwb —— Harmony encode* 函数与之逐字节
对齐已由既有 Replay 覆盖，本相补全写侧取证链。

## 7. 验证

`d02-struct-writers.mjs` 静态断言。
