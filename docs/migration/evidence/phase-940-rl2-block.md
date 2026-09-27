# Phase 940 证据 — `rl2` CreateBlock 21 字段偏移图

## 完整表（访问器→偏移实证）

| 访问器 | 偏移 | 字段 | 类型 |
|---|---|---|---|
| `B()` | c(4) | type | cz0{TEXT,IMAGE,MATH} |
| `j()` | c(6) | corner | ty0{SQUARE,ROUND} |
| `t()` | c(8) | page | cxc |
| `s()` | c(10) | origin | fqa |
| `x()` | c(12) | rotation | Float |
| `y()` | c(14) | scale | qed |
| `z()` | c(16) | size | qed **必需** |
| `A()` | c(18) | textWrap | ive |
| `l()` | c(20) | enableCaption | bool |
| `D()` | c(22) | zIndex | tmf ULong |
| `m()` | c(24) | image | dp5 |
| `k()` | c(26) | cropRect | bmb |
| `C()` | c(28) | webUrl | String |
| `r()` | c(30) | mathLatex | String |
| `q()` | c(32) | mathColor | hu1 |
| `u()` | c(34) | paper | k3a |
| `n()` | c(36) | flipHorizontal | bool |
| `o()` | c(38) | flipVertical | bool |
| `w()` | c(40) | resizesWidthToFitText | bool |
| `p()` | c(42) | margins | vy7 |
| `v()` | c(44) | positionLocked | bool |

## 语义注释

- 几何组：page+origin+rotation+scale+size
  （f2-f8）——与 ink/shape 相同的变换头。
- 内容组按 cz0 判别：TEXT→paper/textWrap、
  IMAGE→image/cropRect/webUrl、MATH→mathLatex/
  mathColor。
- 变换尾部：flip×2+resizeToFit+margins+
  positionLocked（ar6=7 后引入）。

## 结论

CreateBlock 21 槽全钉死——最大单 op 表。
