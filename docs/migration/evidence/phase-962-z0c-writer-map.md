# Phase 962 — `z0c` 匿名写器族：完整 型→写器函数映射

来源：`decompiled_1.0.3/sources/defpackage/z0c.java`、`yec.java`

## 1. `z0c` 结构（R8 λ 归并）

`z0c` = `/* synthetic */ Function0`（`I`=变体标签）；
`invoke()` case 21 = **mx7 结构注册表**、case 24 = **IdentityHashMap
表注册表**（ree.a 所用）。每个 put 创建**匿名 wx4 实例**——
R8 将数十个 λ 归并成共享类 `ywd`/`yec`，其 `invoke` 内层
`switch(捕获序数)` 实现"哪个λ"分派。

## 2. 结构写器函数全表（15 型，`yec`/`ywd` 分派体实证）

| 类型 | 写器函数 | 载体 |
|------|----------|------|
| ua0 | `aa6.x0` | yec case27 |
| v01 Boundary | `rz1.b0` | yec/ywd |
| hd1 CanvasAnchor | `y5j.c` | yec/ywd |
| hu1 Color | `z5c.P` | yec/ywd |
| xq3 DuplicateOp | `vfj.d` | yec case21 |
| qo5 Id | `rh8.O` | yec case22（953 实证） |
| vy7 Margins | `fsi.b0` | yec case23 |
| fqa Point | `apb.Y` | yec case24 |
| ukb RecordingSegment | `ddj.b` | yec case25 |
| bmb Rect | `ldj.A2` | yec case26 |
| cwb ReplyAnchor | `efj.b` | yec case28 |
| cxc SeqId | `nti.X` | yec default（945/954 实证） |
| qed Size | `apb.Z` | ywd case0 |
| utf Uuid | `wtf.b` | ywd case2 |
| yyd StyleMap | **内联**（t(4,20)+2f+t(4,8)+2f+w(seed)） | ywd case1 |

## 3. 表写器函数（`ywd` cee 分支，28 例）

`tsi.c`(uf7) `j0j.e`(td8) `l0j.c`(vd8) `fwi.c`(gd)
`o0j.f`(wd8) `r0j.d`(ge8) `v0j.d`(he8) `p0j.d`(ee8)
`w0j.d`(ie8) `x0j.m`(je8) `z0j.l`(ke8) `a1j.c`(le8)
`c1j.c`(me8) `n4j.c`(oz8) `q4j.b`(r29) `q5j.b`(q89)
`zq9.d`(uq9) `w6j.c`(vq9) `x6j.b`(vt9) `kvi.f`(p9)
`vv7.L`(nz9) `fag.n0`(k3a) `j7j.c`(sw9)

其余 ~37 表项走其它匿名 wx4（墨迹/形状/字符/setter 系，
`zwd.a` 内联结构向量在 947/949 已实证）。

## 4. 关键实证

- **apb.Y/Z = Point/Size 写器对**（同类双方法）
- `new yec(N)`/`new ywd-anon` 的 N = λ 判别序数
- `mx7` 键 = `npb.b(Class)` KClass；IdentityHashMap 键 =
  `.class` 引用——容器语义差异保持（961）

## 5. Harmony 对齐

写器函数表 = Harmony 写侧分派表的实证清单——
Harmony 注册表应镜像全部 80 项的型→写器映射。

## 6. 验证

- `d02-z0c-writer-map.mjs` 静态断言 15 结构 + 23 表写器名。
