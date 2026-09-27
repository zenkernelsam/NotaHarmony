# Phase 870 证据 — 墨迹 op payload 模式登记（类型 15–17）

## 目的

登记 `haa` 15–17 墨迹三表的字段模式：`dm2` CREATE_INK、
`gd` ADD_PATH_ELEMENTS、`wd8` MODIFY_INK；核对 Harmony 墨迹
op 编码器。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### zq9 映射

```
dm2 -> CREATE_INK(15)   gd -> ADD_PATH_ELEMENTS(16)   wd8 -> MODIFY_INK(17)
```

### `dm2` — CREATE_INK（19 个 vtable 槽，f0–f19 缺 f9）

已定位读法（偏移→字段号=(n-4)/2）：

| 偏移 | 字段 | 读法 | 语义 |
|------|------|------|------|
| c(4) | f0 | `t()` → cxc | 位置 |
| c(8) | f2 | `u()` → Float | |
| c(10)/12/14/16 | f3–f6 | （工具/样式子字段） | |
| c(18) | f7 | `k()` → hu1 | 颜色 RGBA |
| c(24)/26 | f10/11 | `l()/m()` → Integer | |
| c(28) | f12 | `n()` → hu1 | 第二颜色（填充） |
| c(34) | f15 | `j()` → mmf | 墨迹 id 序数 |
| c(36) | f16 | `p()` → boolean | |
| c(38) | f17 | `r()` → ymf | 路径元素/样式 |
| c(40) | f18 | `o()` → long | |
| c(42) | f19 | `p()` 区另有 boolean | |

另有 `q()`→ymf、`s()`→fqa、`v()`→qed 等子结构读法 —— 路径
几何/工具描述子表。

### `gd` — ADD_PATH_ELEMENTS

`j()` → qo5 目标墨迹 id；正文为路径元素向量（elements
append 到既有 ink）。

### `wd8` — MODIFY_INK（**连续 19 字段** f0–f18）

| 偏移 | 字段 | 读法 | 语义 |
|------|------|------|------|
| c(4) | f0 | `B(qo5,int)`/`a()` | **qo5 向量**（目标墨迹 ids） |
| c(6) | f1 | `t()` → cxc | 位置 |
| c(8) | f2 | `s()` → fqa | |
| c(10) | f3 | `u()` → k2d | setter 表 |
| c(12) | f4 | `v()` → y2d | setter 表 |
| c(14) | f5 | `w()` → t16 | **样式更新** |
| c(16) | f6 | `j()` → hu1 | **颜色更新** RGBA |
| c(18) | f7 | `z()` → Float | **宽度更新** |
| c(20)/22/24 | f8–f10 | `k()/l()/m()` → Integer | |
| c(26) | f11 | `n()` → g2d | setter 表 |
| c(28) | f12 | `C(yyd,int)`/`x()` | **yyd 向量**（styleMap） |
| c(30) | f13 | `A()` → tmf | 时间戳 |
| c(32)/34 | f14/15 | `q()/r()` → ymf | 路径元素 |
| c(36) | f16 | `y()` → ife | |
| c(38) | f17 | `o()` → tmf | |
| c(40) | f18 | `p()` → Boolean | |

（k2d/y2d/g2d/t16 = modify-setter 表；ymf/yyd = 路径元素/
styleMap 结构。）

## Harmony 侧（`note/src/main/ets/data`）

- `OriginalCreateInkPayloadEncoder` / `OriginalCreateInkOperation`
- `OriginalAddPathElementsPayloadEncoder` / `Operation`
- `OriginalModifyInkPayloadEncoder`：**19 槽 vtable**（
  `new Array(19)`），fields[0]=4（f0 目标/位置）、
  fields[5]→style(k2d 对应槽 c(14))、fields[6]→color
  (hu1 c(16))、fields[7]→width(c(18))、fields[12]→styleMap
  向量 —— 与原版字段索引逐项一致；style 存在时写空
  style-map 向量（`u5j.q` 语义）。
- `OriginalInkPathCodec`/`OriginalInkPathEncoder`/
  `OriginalInkStyleMapCodec`：路径几何/样式映射子层。

## 结论

墨迹三表模式登记完毕；Harmony 写手与 wd8 19 字段布局逐项
对齐（f0/f5/f6/f7/f12 锚点一致）。dm2 深层子字段（fqa/
ymf/qed 几何）留档备查。纯文档+fixture 阶段。
