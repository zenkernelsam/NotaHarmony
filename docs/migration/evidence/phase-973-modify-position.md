# Phase 973 — `ie8` ModifyPosition 条目 + `w0j.d/e` 写器

来源：`decompiled_1.0.3/sources/defpackage/{ie8,w0j}.java`

## 1. `ie8` = ModifyPosition（je8 MODIFY_POSITIONS 元素）

toString：`ModifyPosition(target,page,origin,rotation,
scale,zIndex)`。

## 2. `w0j.d/e` 写器（C(6)，required f0）

```java
e(a, qo5 target, cxc page, fqa origin,
   k2d rotation, y2d scale, tmf zIndex):
rot = rotation != null ? ngh.d(rotation,a) : null;  // k2d SetFloat 表
scl = scale    != null ? zgh.c(scale,a)    : null;  // y2d setter 表
aVar.C(6);
j(0, rh8.O(target));           // f0 = 目标实体 qo5 必需
if (page)   j(1, nti.X(page)); // f1 = 跨页移动目标 cxc
if (origin) j(2, apb.Y(origin));// f2 = 新原点 fqa
if (rot)    h(3, rot);         // f3 = rotation setter 表
if (scl)    h(4, scl);         // f4 = scale setter 表
if (zIndex) f(5, tmfVar.I);    // f5 = zIndex（long!）
z(iN,4);
```

- rotation/scale 经 **setter 子表**（k2d/y2d）——与
  td8/le8 的 setter 包装一致。
- `tmf.I` 经 `aVar.f(5,long)` 写入 → **tmf = long 值类
  （ZIndex）**。
- `w0j.f(int)` = 0..5→1..6 映射小助手（层序转换）。

## 3. 与 je8 的联结

`x0j.m(je8)` = `C(1)` + req f0 = `ie8[]` 向量（经
`w0j.e` 逐元素序列化 + CAS 偏移收集）。

## 4. Harmony 对齐

Harmony 原稿 zIndex 用 int；原版为 **long**（tmf.I）——
位宽差异已在 td8/le8 evidence 登记，此相再次实证。

## 5. 验证

`d02-modify-position.mjs` 静态断言。
