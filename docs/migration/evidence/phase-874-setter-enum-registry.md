# Phase 874 证据 — 修改 setter 包装族 + op 枚举登记

## 目的

登记 MODIFY_* payload 内统一的单字段 setter 包装表与实体/
工具枚举集。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### setter 包装表（统一形态：`{f0: T}`，存在=改、缺省=不改）

| 表 | f0 类型 | 语义 |
|----|---------|------|
| k2d | Float | 浮点更新（宽/距等） |
| y2d | qed | 2-float 尺寸更新 |
| z2d | String | 字符串更新（标题/文本/名） |
| g2d | hu1 | 颜色更新 |
| p2d | bmb | bmb 结构更新 |
| n2d | k3a | 纸张背景更新 |

所有 MODIFY_* 表复用同一套包装——`le8`/`wd8`/`td8`/`ke8`/
`ud8`/`l2d` 均以 `?2d` 槽位表达可空更新。

### 枚举集

| 枚举 | 值 | 语义 |
|------|-----|------|
| u16 | PEN,PENCIL,HIGHLIGHTER,TAPE,WHOLE_ERASER,PARTIAL_ERASER,SELECTION,LASER | **线层工具枚举**（墨迹 f6 工具槽） |
| t16 | VARIABLE_WIDTH,FIXED_WIDTH,DASH,DOTS | 墨迹样式 |
| ife | STRIPES,GRID,DOTS,PLAIN,STARS,FLOWERS,HEARTS,WAVES,CHECKERS | 形状填充图案 ×9 |
| z4d | NONE,LINE,POLYGON,NORMAL_SHAPE | 形状种类 |
| ty0 | SQUARE,ROUND | 块角类型 |
| ive | PIXEL_ALIGN,NO_WRAP | 标志位 |
| im | NONE,CANVAS_ANCHOR,TEXT_ANCHOR,ENTITY_ANCHOR,REPLY_ANCHOR | 批注锚类型 |
| oz9（865） | UNBOOKMARKED,BOOKMARKED | 页书签 |
| n3a（868） | LINES,DOTS,GRID | 纸纹 |
| xw9（868） | DOWNSCALING_AND_MAX_BOX,DOWNSCALING_AND_CROP_BOX,FIT_AND_CROP_BOX | PDF 适配 |

### 其他子结构（结构性留档）

- struct：`hu1`(RGBA4B)、`qed`(2f)、`vy7`(4f)、`fqa`、`v01`、
  `ukb`(录音段)、`bmb`、`tmf`(u64 挂钟)、`qo5`(op-id)。
- table：`m2d`(背景更新，内嵌 nz9)、`lxc`(moveTo)、`k3a`(纸张)、
  `wa0`(pdf 资产)、`akb`(录音 id)、`dp5`、`cm2`/`g2d`。
- `xgb`/`tmf`/`ymf`：挂钟/路径元素结构。

## Harmony 侧

- `OriginalCreateInkOperation`：`readUint8(4)` 直接按 u16 线值
  解码（1=pencil/2=highlighter/3=tape/5=partialEraser，门限
  排除 4=WHOLE_ERASER/6=SELECTION/7=LASER 作为可创建墨迹）——
  线层枚举逐值一致；`BrushTypes` 的本地编号是 UI 层 `a6f`
  枚举，不与线值混用。
- setter 语义由 `update.X === null ? 0 : offset` 表达（各
  ModifyXxxPayloadEncoder 的 null-gate）——与 `{f0: T}` 包装
  的「存在即改」语义对应。

## 结论

setter 包装族（6 表单字段可空更新）与九枚 op 枚举全部登记；
u16 线层工具值在 Harmony 解码端逐值一致。纯文档+fixture。
