# ADR-1124：瓦片渲染模型（ContentInputs + 可绘笔画）

## 状态

已接受（Phase 1180）。

## 决策

- `h0f`=`ContentInputs` = GL 画布渲染输入：
  `noteGeneration`（版本脏检测）+ `zoom` + **瓦片
  `tileWidth/tileHeight`**（分块渲染+脏区剔除）+
  `useBezier`（笔画贝塞尔 tessellation）+ `showTileBorder`
  + erase/selection/pdf-text 态 → Harmony 渲染输入
  struct 语义保留。
- 瓦片渲染策略 → Harmony XComponent/Drawing 瓦片
  + 脏区剔除。

## 理由

`ContentInputs` toString 实名 + tileWidth/Height +
useBezier + pwd/mwd Path+BlendMode 可绘。

## 后果

Harmony 画布 = 瓦片化渲染（性能对齐原版脏区剔除）+
贝塞尔笔画平滑 + 选择/擦除/PDF 文本态。
