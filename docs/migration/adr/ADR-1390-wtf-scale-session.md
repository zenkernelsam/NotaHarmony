# ADR-1390：角柄 wtf(Scale) 会话——双轴缩放、fixedCorner 枢轴、无旋转

## 状态

已实施（Phase 1455），含登记差异。

## 背景

Phase 1453 解码 1.4.2 变换会话族时已确认 `wtf`(Scale) 会话无角度
字段，但当时 `guf.r/s`（会话调度协程）反编译失败，角柄沿用
1.0.3 `htc.e`/"距离比缩放+角位移旋转"自由变换语义并登记差异。

本 Phase 通过 `ms1.java:330-435` 构造点、`guf.f` 缩放比函数、
`guf.h` 双轴应用函数补齐语义链：

- `wtf` 字段：`axis`/`xAxis`/`yAxis`（选区旋转系内向量）+
  `locksAspectRatio` + `fixedCorner`；
- `guf.f`：`s_axis = 1 + Δ·axis/|axis|²`（Δ=cur−dragStart 位移投影）；
- `guf.h`：逐成员 `(pos−page−pivot)→逆元素旋转→×(sx,sy)→正旋→还原`
  双轴缩放，`jv6` 文本有 16px 字号下限，`z` 页框钳制；
- `z7=locksAspectRatio`：默认 true，仅 `lsf ∧ vvh`（文本块）false。

## 决定

- `applySelectionResize` 拆为两支：旋转柄=vtf（纯旋转+90°吸附，
  不变）；角柄=wtf——`Δ=p−dragStart`，
  - 锁等比（默认）：`s = 1+Δ·axis/|axis|²` 统一双轴；
  - 自由（lsf+单文本块）：`sx=1+Δx/axisX`、`sy=1+Δy/axisY`；
  - 经 `resizeSelectedAxes` 施 `T(fixed)·S(sx,sy)·T(−fixed)·base`，
    **零旋转分量**。
- 角柄命中域改为原版 `±44/zoom` 文档方框（屏上 `±44vp`，
  `SELECTION_CORNER_HIT_HALF`），替代 Ø44vp 圆。
- `resizeStart` 在角柄支改存实际触点（`wtf.c` 语义），按下瞬间
  s=1 无跳变。

## 登记差异

1. **文本 16px 字号下限未实现**（`guf.h` 的 `fD2/fC2` 地板依赖
   `jv6.a()` 字体度量——Harmony 文本块无对应查询路径）；
2. **页框钳制未实现**（`guf.a` 的 `z` 支——Harmony 变换不钳页界）；
3. **选区旋转系退化**：原版轴向量经 `kw9.c` 旋入旋转选区系，
   Harmony 覆盖层为轴对齐 AABB（旋转烘焙入元素 transform），
   轴=画布 x/y——已旋转选区的角柄沿屏幕轴缩放而非原选区轴；
4. `guf.r/s` 调度协程仍反编译失败，lock 等比的"对角投影"公式
   系 `axis` 字段角色推断——但 `s=1+Δ·axis/|axis|²` 与
   `guf.f` 数学同构，语义置信度高。

## 后果

- 角柄拖拽行为从"等比径向缩放+自由旋转"变为"对侧角枢轴双轴缩放
  （默认等比/单文本自由）"——与 1.4.2 一致；旋转仅由旋转柄产出。
- 角柄命中面积 4 倍（88vp 方框 vs Ø44vp 圆）对齐原版容差。

## 验证

- `d02-original-scale-session-wtf.mjs` 20 项（字段/命中/构造/
  投影/矩阵/撤销通道 + 可执行数学模型）。
- `d02-original-selection-resize.mjs` 36 项（语义断言全面更新）。
- `d02-original-selection-rotate-snap.mjs` 13 项（差异 pin 更新）。
