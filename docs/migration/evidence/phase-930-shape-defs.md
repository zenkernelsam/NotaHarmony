# Phase 930 证据 — `z5c.a0` 形状定义分发 + z4d + 三定义类

## 目的

CreateShape `definition` 多态全链实名（912 判别子
字段的下游闭合）。

## `z5c.a0(z4d)` 工厂开关（实证）

```java
switch (z4d.ordinal()) {
  case 0: return null;        // NONE
  case 1: return new uf7();   // LINE
  case 2: return new pra();   // POLYGON
  case 3: return new oz8();   // NORMAL_SHAPE
}
```

`z5c.v(ao2)`/`z5c.w(le8)`：先读 `l()`/`m()` 得 z4d
判别子 → `a0` 造具体类 → `cee.d()` 在 f5/f6 子表
偏移初始化。

## `z4d` = `ShapeDefKind`

`{NONE=0, LINE=1, POLYGON=2, NORMAL_SHAPE=3}`。

## 三定义类（toString 实证）

- `uf7` = **`Line{start:fqa, controlPoint1:fqa,
  controlPoint2:fqa, end:fqa, arrowHead:?}`** ——
  贝塞尔线+箭头。
- `pra` = **`Polygon{points:List}`** —— 点向量
  （lv2.a0 物化器）。
- `oz8` = **`NormalShape{type:?, size:?}`** ——
  预置形（矩形/椭圆等）type+size。

## 附带：`z5c.Z(cxc)` = `"{site},{ts},{idx}"`

cxc 位置 ID 字符串化：`ymf.a(c())+","+mmf.a(d())+
","+mmf.a(C())`（UShort,UInt,UInt）——调试/日志格式。

## Harmony 核对

CreateShape definition 分发对齐：z4d 判别 +
uf7/pra/oz8 三类形状定义表。

## 结论

形状多态全链闭合：判别子→工厂→三定义表实名。
