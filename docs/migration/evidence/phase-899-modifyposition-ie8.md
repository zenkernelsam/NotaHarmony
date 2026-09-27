# Phase 899 证据 — `ie8`=ModifyPosition(type24) + 值类家族补全

## 目的

实名 type-24 载荷与 k2d/y2d setter、tmf 值类。
`decompiled_1.0.3`。

## `ie8` = `ModifyPosition`（type 24，toString+注册证实）

`ModifyPosition(target=, page=, origin=, rotation=,
scale=, zIndex=)`：

| 访问器 | 类型 | 语义 |
|--------|------|------|
| `n()` | `qo5` | **target**：被移动元素的 op-id |
| `k()` | `cxc` | **page**：页面位置（12B CRDT 位） |
| `j()` | `fqa` | **origin**：x/y 点 |
| `l()` | `k2d` | **rotation**：SetFloat 包装 |
| `m()` | `y2d` | **scale**：SetSize 包装 |
| `o()` | `tmf` | **zIndex**：ULong 包装 |

- `x0j.java:290` `new q5(24, ie8, je8)` = **payload type 24**
  注册（applier `je8`）。
- `w0j.a(qo5,cxc,fqa,k2d,y2d,xgb,int)` = 工厂（尾部 int =
  Kotlin $default 掩码，同族模式）。
- `w0j.d(ie8,a)` = 序列化器 → `e(aVar, n,k,j,l,m,o)`。
- 构建路径：`ie8.d(...)` init + `ybg.c(ie8Var)` = 解析后
  校验驱动（862）。
- `qsa.d(uq9, ie8)` = applier 派发接口槽。

## `ddg.e(ie8)` 校验映射（回填 895）

`o(k(),j())` = page+origin 位置点对校验；
`l("Rotation", k2d.j())` = 旋转有限性；
`j(y2d.j())` = 缩放有限性——三可选字段各自校验。

## Setter 包装实名

- `k2d` = `SetFloat{value:Float}`（toString）。
- `y2d` = `SetSize{value:qed}`（toString）。

## `tmf` = Kotlin ULong 值类（家族补全）

`long I` + `njj.h0` 无符号比较 + `njj.j0(10,I)` 无符号
格式化 = **ULong**。家族闭环：

| 类 | 基础类型 | Kotlin 型 |
|----|----------|-----------|
| `mmf` | int | UInt |
| `ymf` | short | UShort |
| `tmf` | long | ULong |

zIndex 语义 = ULong 排序键（CRDT z-序）。

## Harmony 侧

- 位置修改 op ↔ ModifyPosition 六可选字段编码；
  SetFloat/SetSize setter 包装 ↔ 单字段修改表；
  zIndex ULong ↔ 元素层序。

## 结论

type-24 ModifyPosition 全字段+setter 包装+ULong 实名；
无符号值类家族（UInt/UShort/ULong）闭环。
纯文档+fixture 阶段。
