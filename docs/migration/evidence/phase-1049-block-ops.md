# Phase 1049 证据 — 块/位置/删除操作载荷

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `rl2` CreateBlock（19 字段，StringBuilder toString 实名）

`{type:cz0, corner:ty0, page:cxc, origin:fqa, rotation:Float,
scale:qed, size:qed, textWrap:ive, enableCaption:bool,
zIndex:tmf, image:dp5, cropRect:bmb, webUrl:String,
mathLatex:String, mathColor:hu1, paper:k3a,
imageFlippedHorizontally, imageFlippedVertically,
resizesWidthToFitText, margins:vy7, positionLocked}`

## `td8` ModifyBlock（16 字段）

`{blocks:list(lv2.u), corner, page, origin, rotation, scale,
size, textWrap, enableCaption, zIndex, mathLatex, mathColor,
cropRect, paper, imageFlippedHorizontally,
imageFlippedVertically}`——blocks>0（"Must specify more
than 0 Blocks"）。

## `je8` ModifyPositions

`{modifications:list(lv2.S)}`——"Must target more than 0
Inks/Shapes/Blocks"。

## `s83` DeleteEntities（软删除/恢复四列表）

`{entityDeletes(lv2.I), entityUndeletes(lv2.J),
pageDeletes(lv2.W), pageUndeletes(lv2.X)}`——
删除/恢复 分离建模（墓碑 + undelete）。

## 新枚举

| 类 | 值 |
|---|---|
| `cz0` 块类型 | TEXT=0 IMAGE=1 MATH=2 |
| `ty0` 圆角 | SQUARE=0 ROUND=1 |
| `ive` 文本环绕 | PIXEL_ALIGN=0 NO_WRAP=1 |

## 新类型

`dp5`=image 引用（cp5 资产同源）、`bmb`=cropRect、
`k3a`=paper、`vy7`=margins（m09 默认值同源）。

## HarmonyOS 决策

- 块 19 字段语义保留（mathLatex/webUrl/翻转/边距）；
  软删除四列表模型保留；枚举 wire 对齐。

## 产出

- fixture `d02-block-ops.mjs`（12 断言）。
- ADR-0993；中文报告。
