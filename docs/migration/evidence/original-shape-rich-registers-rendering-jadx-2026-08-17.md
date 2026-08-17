# 原版 Shape 富寄存器、Path 与渲染边界证据（JADX，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `sources/defpackage/ao2.java`：
  `AFE6563BF454613F3076959ECC7D9B4BCF1536E3AFC74A5A7F7FB7EF578A422F`
- `sources/defpackage/le8.java`：
  `68922497E37AA444014712A62A6287977DD26912BD8B3FC05593C9F78B9270DB`
- `sources/defpackage/k16.java`：
  `A81D0EFC4E2E0D5A19D817E7E6E0BCA0A7774DF1BFB67E89E53F132167F71627`
- `sources/defpackage/p16.java`：
  `42AF20595D902EA566E3A2039BF265F6B8094F68415D838CFA14B557F8CA95C8`
- `sources/defpackage/y4d.java`：
  `22E4F85A4AF50A4D16E81AA48FFFE3B68D335067B3C2533E49DF886623B1C94E`
- `sources/defpackage/xai.java`：
  `442346ECC33F91E1910E0B80EF72FD6880F8C7ACEF393AE6EE6EA9039F6467E6`
- `sources/defpackage/l96.java`：
  `FE118CD08E93845CC7625ED8692162D8B720F00DC6FDDF5FD35844B73F7EF0C4`

## 1. CREATE_SHAPE 不允许 variable-width，但保留完整 Shape 寄存器

`ao2.java:14-33` 是 CREATE_SHAPE 的业务校验：

- style 为 variable-width 时返回 `Cannot create shapes with variable width ink`；
- 无填充必须写 `nil`，不能用 alpha=0 的伪透明颜色；
- `ink_effects_tinted=true` 要求 effect 非零；
- effect 只允许 Pen 或 Highlighter。

这证明本地识别不能把 Ink 的 VARIABLE_WIDTH style=0 原样写进 Shape。原版渲染自身也在
`k16.java:204-209` 将 `t16.VARIABLE_WIDTH` 置空后回退到 `t16.FIXED_WIDTH`。因此 Harmony 对识别结果采用
style=1 的固定宽度降级，并继续保留已经预约的 CREATE_SHAPE identity；把 style=0 留在本地 Shape 会制造原版
无法出站且自有包校验拒绝的状态。

`le8.java:216` 的 `ModifyShape(...)` 字符串同时列出 `tool/style/tapePattern/color/borderWidth/fillColor/zIndex/
positionLocked/inkEffects/inkEffectsTinted`。TapePattern、effect 和 tint 是独立 LWW register，不能因为某个 renderer
当前不消费就从模型、持久化、Clipboard 或 ModifyShape 中删除。

## 2. Shape 保存 TapePattern，但本体不绘制 Tape 图案

`k16.java:152` 将 Pencil Shape 分到独立分支。非 Pencil 分支构造 `nwd` 时，`k16.java:212` 的尾部参数为：

```java
..., cf0Var.a, cf0Var.b, null, 0, 198144
```

其中 TapePattern 位置明确传 `null`。因此正确边界是：

1. Shape 的 Tape register 继续入站、Modify、持久化和复制；
2. Shape 本体按普通中心线/Shape border 绘制，不调用 Ink 的 `qfe` Tape pattern renderer；
3. Shape 经 Partial Eraser 转成 Ink 残片后，保留下来的 Tape register 才进入 Ink Tape 渲染。

早期 Harmony 直接把 Shape 临时组装成 Stroke 并调用 `renderTapePattern()`，会在原版 Shape border 上额外叠一层
图案，且错误引入 viewport zoom bucket。这不是“更完整”，而是跨越了原版 consumer 边界。

## 3. 原版 ShapeDefinition 保留原始 Path verb

`xai.java:130-177` 直接把 ShapeDefinition 转为 Android `Path`：

- LINE 根据定义调用 `cubicTo`、`quadTo` 或 `lineTo`；
- Ellipse 调用 `addOval`；
- Polygon 逐点 `lineTo` 后 `close()`。

因此渲染层不能把带控制点的 LINE 永久退化为采样折线。Harmony 使用一个 cubic segment 表达 LINE，四个 cubic
表达旋转 Ellipse，并把 Polygon 作为闭合中心路径；Canvas、Pencil splat 与缩略图消费同一语义几何。

## 4. 箭头裁剪发生在原始 Path 上

`l96.java:5200-5231` 对 LINE 创建 `PathMeasure`：先读取总长和末端，再在 `length-arrowLength` 位置读取箭头基点，
最后通过 `getSegment(0,f4,path3,true)` 截取主干。该主干来自原始 line/quad/cubic Path，不是把 64 个采样点重新
连成可见折线。

Harmony 仍可用有界采样估计弧长参数，但确定参数后必须通过 de Casteljau 截取原 quadratic/cubic，保留原始 verb；
箭头作为第二个独立子路径。这样主画布的曲线不产生固定折线拐点，Pencil walker 也继续取得一个原生 cubic segment。

## 5. Pencil Shape 和箭头使用确定性 seed

`p16.java:155` 调用 `y4d.b(...,1544949492L,...)`；`y4d.java:77-103` 先经 `xai.d()` 和 `l96.W()` 获得主干/箭头，
随后分别执行：

```java
wg6.q(listA,  d, x4dVar, j,          null)
wg6.q(listA2, d, x4dVar, 1544949492L, null)
```

第二个箭头子路径会重置为固定 fallback seed。Harmony 因此为每个 Shape 子路径创建独立 generator，并在主干和
箭头开始前都重置 `1544949492`；缓存按 Shape ID、几何、force 和 stroke width 校验，32 项/262144 splat 有界，
编辑器或缩略图 renderer dispose 时清空。

## 6. 适配结论

- Shape 模型完整保留 Tape、smart-highlight、force、effect、tint 与 reserved CREATE_SHAPE identity。
- CREATE_SHAPE 使用完整 18 字段、8 字节对齐的原版 table；ModifyShape 先解析全部 winner，再统一验证并写 journal。
- 原版拒绝的 style/effect/fill/definition 组合必须在本地出站、自有包和入站 materialization 三层一致拒绝。
- Clipboard 只重置 smart-highlight 和 create identity；legacy create force 要提升为稳定 Shape force。
- Partial Eraser 输出 Ink 时保留 force、Tape 和 effect 元数据。
- Shape Tape register 不等于 Shape Tape 图案 renderer；二者必须分层记录。

## 验证边界

静态 fixture/replay 能证明字段、校验、Path verb、seed、缓存、consumer 边界与生命周期；仍需设备验证 Pen/
Highlighter/Pencil/Tape 来源 Shape 的真实像素、曲线箭头端点、缩放/旋转、主画布与缩略图一致性、保存重启及
Partial Eraser 后 Ink Tape 图案。
