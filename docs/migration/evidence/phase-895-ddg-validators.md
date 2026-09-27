# Phase 895 证据 — `ddg` 校验助手全集 + ka4 实现者扩展

## 目的

补全 `ddg` 共享校验静态类其余助手；确认 qed/vy7/fqa
亦为 ka4 实现者。`decompiled_1.0.3`。

## `ddg` 助手清单（实证）

| 方法 | 语义 |
|------|------|
| `a(f,f2)` | **ε 比较器**：`\|f−f2\| < 1e-4`（基向旋转判定用） |
| `d(f)` | float 有限性：`"Cannot be infinite"`/`"Cannot be NaN"` |
| `l(label,f)` | `d(f)` + `"label: err"` 前缀包装 |
| `i(qed)` | **尺寸校验**：width/height ≥0 + 有限性 |
| `j(qed)` | **缩放校验**：d(d)/d(c) → `"Scale invalid: ..."` |
| `k(ka4,label)` | ka4 委托 + `"label: err"` 前缀（ddg.f 内
`k(qedVar,"Crop box")` 证实 **qed 是 ka4**） |
| `h(fqa)` | 点校验：`l("x",c())`+`l("y",d())` |
| `e(ie8)` | 文本修改校验：`o(k(),j())` 位置+styleMap +
`l("Rotation",k2d.j())` 旋转 + `j(y2d.j())` 缩放 |
| `m(nl8,num)` | **centerPath 校验**：`"CenterPath full path
error: X"` + styleMap-per-moveto 规则 `"Non-empty styleMap
must have one entry per moveto path element in centerpath"`
+ 解码异常包装 `"Error decoding centerPath: e"` |
| `b(po4)`/`c(long)`/`n(hmf,str,bool)`/`o(cxc,fqa)` | 路径元素/
长整数/路径迭代/位置-点对校验（同族） |

## ka4 实现者扩展

894 已证：ln2/sw9/wa0/nz9(经 k)/k3a/vy7/fqa/tdf…
895 新增实证：**qed**（`k(qedVar,...)` 直调 ka4 接口）、
**vy7**（`vy7VarJ.a()` 直调）、**fqa**（`h()` 内 ka4 语义）。
全部 cee/xwd 载荷类实现 ka4 = **生成层统一校验面**。

## 关键语义

- float 比较统一 ε=1e-4（旋转/缩放/位置一致阈值）。
- 校验消息统一 `"<label>: <leaf-err>"` 层级格式。
- centerPath 的 styleMap 一致性 = 路径-样式对齐硬约束。

## Harmony 侧

Harmony 编码侧 throw 门 + 数值守卫 ↔ ε 阈值/有限性/
层级消息格式；centerPath-styleMap 校验 ↔ 墨迹路径
编码一致性门。

## 结论

ddg 校验助手全集实名（ε 比较/有限性/尺寸/缩放/点/文本/
路径）；ka4 实现面扩展至 qed/vy7/fqa——wire 层校验体系
闭合。纯文档+fixture 阶段。
