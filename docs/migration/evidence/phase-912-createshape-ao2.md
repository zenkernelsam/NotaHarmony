# Phase 912 证据 — `ao2` = `CreateShape` 18 字段读图

## 目的

形状创建 op 载荷实名（871 写侧注册的读侧补全）。

## `ao2` = `CreateShape`（toString 实证）

`CreateShape(page=, origin=, rotation=, scale=,
definition=, tool=, style=, tapePattern=, color=,
borderWidth=, fillColor=, zIndex=, smartHighlight=,
force=, positionLocked=, inkEffects=, inkEffectsTinted=)`

## accessor→字段图

| 访问器 | c(N) | 字段 | 类型 | 语义 |
|--------|------|------|------|------|
| `r()` | c(4) | f0 | `cxc` | page |
| `q()` | c(6) | f1 | `fqa` | origin |
| `t()` | c(8) | f2 | Float | rotation |
| `u()` | c(10) | f3 | `qed` | scale |
| `l()` | c(12) | f4 | `z4d` byte | **definition 种类判别子** |
| `z5c.v` | c(14) | f5 | `cee` 子表 | **definition**（多态） |
| `y()` | c(16) | f6 | `u16` | tool |
| `w()` | c(18) | f7 | `t16` | style |
| `x()` | c(20) | f8 | `ife` | tapePattern |
| `k()` | c(22) | f9 | `hu1` | **color（必填）** |
| `j()` | c(24) | f10 | float | **borderWidth（默认 4.0f）** |
| `m()` | c(26) | f11 | `hu1` | fillColor |
| `z()` | c(28) | f12 | `tmf` | zIndex |
| `v()` | c(30) | f13 | bool | smartHighlight |
| `n()` | c(32) | f14 | Float | force |
| `s()` | c(34) | f15 | bool | positionLocked |
| `o()` | c(36) | f16 | long | inkEffects |
| `p()` | c(38) | f17 | bool | inkEffectsTinted |

## 关键契约

- `l()` = `z4d` 定义种类枚举：`z5c.v` 以
  `mpb.a.b(ao2Var.l().getClass())` 作类键，经 `a0()`
  分发到具体形状定义子表类——**判别子+子表双字段
  多态**（vs uq9 的 haa 判别+cee 载荷同模式）。
- `k()` color 为必填（`o14.i` required 断言）；
  `j()` borderWidth 缺省 **4.0f**。
- `z5c.w(le8)` 同模式服务 ModifyShape（c(16) 读定义）。
- 枚举 z4d/u16/t16/ife 统一 nz3 回退读法。

## Harmony 核对

`OriginalCreateShape*` 编码对齐：判别子+定义子表、
必填 color、borderWidth 默认 4.0。

## 结论

CreateShape 18 槽实名；形状定义多态机制
（z4d 判别子 + z5c 类键分发）实证。
