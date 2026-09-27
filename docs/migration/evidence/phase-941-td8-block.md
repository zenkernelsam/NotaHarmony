# Phase 941 证据 — `td8` ModifyBlock 18 槽偏移图

## 完整表（访问器→偏移实证）

| 访问器 | 偏移 | 字段 | 类型 |
|---|---|---|---|
| — | c(4) | blocks | qo5[]（lv2 物化） |
| `k()` | c(6) | corner | ty0 |
| `s()` | c(8) | page | cxc |
| `r()` | c(10) | origin | fqa |
| `w()` | c(12) | rotation | **k2d SetFloat** |
| `x()` | c(14) | scale | **y2d SetSize** |
| `y()` | c(16) | size | qed 裸 |
| `z()` | c(18) | textWrap | ive |
| `m()` | c(20) | enableCaption | Boolean 三态 |
| `A()` | c(22) | zIndex | tmf |
| `q()` | c(24) | mathLatex | **z2d SetString** |
| `p()` | c(26) | mathColor | **g2d SetColor** |
| `l()` | c(28) | cropRect | **p2d SetRect** |
| `t()` | c(30) | paper | **n2d SetPaper** |
| `n()` | c(32) | flipH | Boolean |
| `o()` | c(34) | flipV | Boolean |
| `v()` | c(36) | resizeToFit | Boolean |
| `u()` | c(38) | positionLocked | Boolean |

## 与 rl2 CreateBlock 的对照差异

- **setter-wrapped**：rotation/scale/cropRect/
  paper/mathLatex/mathColor 用 Set* 包装
  （LWW 寄存器语义）；Create 为裸值。
- **Boolean 三态**（可空）vs Create 的 bool
  默认——修改 op 区分"不改"与"显式 false"。
- **无 margins 字段**：Create 有 vy7@c(42)，
  Modify 不能改内边距。
- **无 type/image/webUrl**：cz0 判别子与
  资产引用创建后不可变。

## 结论

ModifyBlock 18 槽钉死；Create↔Modify
setter/缺失字段差异确认。
