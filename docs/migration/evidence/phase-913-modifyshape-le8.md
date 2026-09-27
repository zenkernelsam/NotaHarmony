# Phase 913 证据 — `le8` = `ModifyShape` 17 槽读图

## 目的

形状修改 op 载荷实名（CreateShape 对偶）。

## `le8` = `ModifyShape`（toString 实证）

`ModifyShape(shapes=, page=, origin=, rotation=, scale=,
definition=, tool=, style=, tapePattern=, color=,
borderWidth=, fillColor=, zIndex=, positionLocked=,
inkEffects=, inkEffectsTinted=)`

## accessor→字段图

| 访问器 | c(N) | 字段 | 类型 | 语义 |
|--------|------|------|------|------|
| `B(qo5,i)` | c(4) | f0 | `qo5` 向量 | **shapes** 目标集 |
| `r()` | c(6) | f1 | `cxc` | page |
| `q()` | c(8) | f2 | `fqa` | origin |
| `t()`/`z(k2d)` | c(10) | f3 | `k2d` | rotation（setter） |
| `u()`/`A(y2d)` | c(12) | f4 | `y2d` | scale（setter） |
| `m()` | c(14) | f5 | `z4d` | definition 判别子 |
| `z5c.w` | c(16) | f6 | `cee` | definition 子表 |
| `x()` | c(18) | f7 | `u16` | tool |
| `v()` | c(20) | f8 | `t16` | style |
| `w()` | c(22) | f9 | `ife` | tapePattern |
| `l()` | c(24) | f10 | `hu1` | color |
| `k()` | c(26) | f11 | Float | borderWidth |
| `n()`/`j(g2d)` | c(28) | f12 | `g2d` | fillColor（setter） |
| `y()` | c(30) | f13 | `tmf` | zIndex |
| `s()` | c(32) | f14 | Boolean | positionLocked |
| `o()` | c(34) | f15 | `tmf` | inkEffects（ULong） |
| `p()` | c(36) | f16 | Boolean | inkEffectsTinted |

## 与 CreateShape 差异

- 首字段 shapes qo5[]（多目标）vs page。
- rotation/scale/fillColor setter 包装；定义仍是
  判别子+子表双字段（z4d@c(14) + z5c.w@c(16)）。
- 无 smartHighlight/force；inkEffects 读为 `tmf`
  ULong（CreateShape 为裸 long）。
- `lv2.e0` = shapes 目标向量物化器。

## 结论

ModifyShape 17 槽实名；创建/修改 setter 二元性 +
定义多态双字段在形状族二次确认。
