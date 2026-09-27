# Phase 918 证据 — `rl2`=`CreateBlock` / `td8`=`ModifyBlock`

## 目的

块 op 二表实名（872 注册写侧的读侧补全）。

## `rl2` = `CreateBlock`（21 字段，toString 实证）

`CreateBlock(type=, corner=, page=, origin=, rotation=,
scale=, size=, textWrap=, enableCaption=, zIndex=,
image=, cropRect=, webUrl=, mathLatex=, mathColor=,
paper=, imageFlippedHorizontally=, imageFlippedVertically=,
resizesWidthToFitText=, margins=, positionLocked=)`

| c(N) | 访问器 | 类型 | 语义 |
|------|--------|------|------|
| c(4) | B() | `cz0` | **type**（块种类枚举） |
| c(6) | j() | `ty0` | corner |
| c(8) | t() | `cxc` | page |
| c(10) | s() | `fqa` | origin |
| c(12) | x() | Float | rotation |
| c(14) | y() | `qed` | scale |
| c(16) | z() | `qed` | **size（必填 o14.i）** |
| c(18) | A() | `ive` | textWrap |
| c(20) | l() | bool | enableCaption |
| c(22) | D() | `tmf` | zIndex |
| c(24) | m() | `dp5` | image（ImageAsset） |
| c(26) | k() | `bmb` | cropRect |
| c(28) | C() | String | webUrl |
| c(30) | r() | String | mathLatex |
| c(32) | q() | `hu1` | mathColor |
| c(34) | u() | `k3a` | paper |
| c(36) | n() | bool | imageFlippedHorizontally |
| c(38) | o() | bool | imageFlippedVertically |
| c(40) | w() | bool | resizesWidthToFitText |
| c(42) | p() | `vy7` | margins |
| c(44) | v() | bool | positionLocked |

878 `baj.a` 21 参数构造器与此 21 槽一一对应。

## `td8` = `ModifyBlock`（19 字段）

`ModifyBlock(blocks=, corner=, page=, origin=, rotation=,
scale=, size=, textWrap=, enableCaption=, zIndex=,
mathLatex=, mathColor=, cropRect=, paper=,
imageFlippedHorizontally=, imageFlippedVertically=,
resizesWidthToFitText=, positionLocked=)` + `lv2.u`
targets 向量；校验经 `ddg.o(s(),r())`（size/origin
联合规则）。

- blocks qo5[] 多目标首字段；无 type/webUrl/margins
  （不可改项）；setter 语义延续。

## Harmony 核对

块编码 21 槽对齐；`OriginalCreateBlock` 引 cz0/ty0/
ive/dp5/bmb/k3a 命名；必填 size。

## 结论

zq9 块族二表实名；872 创建/修改对偶闭合。
