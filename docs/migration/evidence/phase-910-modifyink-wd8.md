# Phase 910 证据 — `wd8` = `ModifyInk` 19 字段读图

## 目的

墨迹修改 op 载荷实名（CreateInk 的修改对偶）。

## `wd8` = `ModifyInk`（toString 实证）

`ModifyInk(inks=, page=, origin=, rotation=, scale=,
style=, color=, width=, encodedCenterPath=,
encodedCustomPath=, encodedFillPath=, fillColor=,
styleMap=, zIndex=, nibAngle=, nibFlatness=,
tapePattern=, inkEffects=, inkEffectsTinted=)`

## accessor→字段图

| 访问器 | c(N) | 字段 | 类型 | 语义 |
|--------|------|------|------|------|
| `B(qo5,i)` | c(4) | f0 | `qo5` 向量 | **inks**（目标墨迹集） |
| `t()` | c(6) | f1 | `cxc` | page |
| `s()` | c(8) | f2 | `fqa` | origin |
| `u()` | c(10) | f3 | `k2d` | rotation（SetFloat 包装） |
| `v()` | c(12) | f4 | `y2d` | scale（SetSize 包装） |
| `w()` | c(14) | f5 | `t16` | style |
| `j()` | c(16) | f6 | `hu1` | color |
| `z()` | c(18) | f7 | Float | width |
| `k()` | c(20) | f8 | Integer | encodedCenterPath |
| `l()` | c(22) | f9 | Integer | encodedCustomPath |
| `m()` | c(24) | f10 | Integer | encodedFillPath |
| `n()` | c(26) | f11 | `g2d` | fillColor（setter 包装） |
| `x()`/`C()` | c(28) | f12 | `yyd` | styleMap |
| `A()` | c(30) | f13 | `tmf` | zIndex |
| `q()` | c(32) | f14 | `ymf` | nibAngle |
| `r()` | c(34) | f15 | `ymf` | nibFlatness |
| `y()` | c(36) | f16 | `ife` | tapePattern |
| `o()` | c(38) | f17 | long | inkEffects |
| `p()` | c(40) | f18 | Boolean | inkEffectsTinted |

## 与 CreateInk 差异

- 首字段 = **inks 目标向量**（qo5[]），非 page。
- rotation/scale/fillColor 走 **setter 包装**
  （k2d/y2d/g2d）——修改语义用包装器，创建用裸值。
- 无 tool 字段（现有墨迹不换工具）。
- `lv2.M/x/C/F/g0` = 修改侧物化器（与创建侧
  w/B/E/f0 成对）。

## 结论

ModifyInk 19 槽实名；setter 包装 vs 裸值的
创建/修改二元性为协议通则（ie8 同模式）。
