# Phase 949 证据 — `z0c` 全量写端注册表

## `zwd.a(xwd,builder)` 分发（实证）

```java
Map map = pce.getValue();              // z0c(21) 懒注册表
wx4 ser = map.get(mpb.a.b(cls));       // KClass 键
if (ser != null) return ser.invoke(xwd, aVar);
rgc.b(name); throw null;               // 未知类型硬抛
```

## `z0c` = 注册表构建器（80 put() 实证）

**mx7Var — xwd inline-struct 写器（15 类）**：

`ua0, v01, hd1, hu1, xq3, qo5, vy7, fqa, ukb,
bmb, cwb, cxc, qed, yyd, utf`

**identityHashMap — cee 表写器（65 类）**：

- **op 表**：ln2, ge8, yn2, ke8, e46, f46, pub,
  qub, f2c, me8, he8, io1, dm2, gd, wd8, ao2,
  le8, cm2, vd8, rl2, td8, je8, s83, tdf, ee8,
  mqf, yda, tl2, ud8, ra0, l2d
- **形状定义**：uf7, pra, oz8
- **锚**：lhe, my3
- **信封**：r29, uq9, vq9, vt9, zgb, sdf
- **模型**：nz9, k3a, sw9, wa0, akb, dp5
- **setter 包装**：z1d, z2d, k2d, y2d, g2d, m2d,
  n2d, o2d, j2d, a3d, p2d, lxc
  （**b3d SetWritingDirection 不在注册表**——
  无独立写器，由 he8 内嵌写）
- **新类型（未映射）**：p9, r60, yq3, q89, xq3

## 写器实现形式

- `new qee(i)` = 参数化 enum 分发写器
- `wx4 {from class: ywd}` = ywd.java 匿名实现
- `wx4 {from class: pee}` = pee.java 匿名实现
- `new yec(i)` = yec.java 写器（xwd 侧）

## 结论

**写端注册表 100% 登记**——80 个 serializer，
对应读端 zq9 注册 + 信封 + setter + 结构。
zq9(读)↔z0c(写) 双注册表闭环。
