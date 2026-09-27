# Phase 887 证据 — 叶级字段序列化器（apb/fsi/rh8/fag/j7j）

## 目的

登记 `vv7.M`/`nti`/`haj` 链末端的内联结构与字段写器
（`decompiled_1.0.3`；builder 逆序推入→内存正序）。

## 内联结构写器（prep+push 实证）

| 写器 | 结构 | 字节布局 |
|------|------|----------|
| `apb.Z(qed,a)` | qed 8B | `t(4,8)` + `v(fC)`+`v(fD)` → `{d:f32@0, c:f32@4}`（推序逆排） |
| `fsi.b0(vy7,a)` | vy7 16B | `t(4,16)` + `v(fE,fD,fC,f)` → `{f@0,c@4,d@8,e@12}` |
| `rh8.O(qo5,a)` | qo5 8B | `t(4,8)` + `w(iD)`+`s(2)`+`y(sC)` → `{site:u16@0, pad:u16=0@2, timestamp:u32@4}` |
| `rh8.b(int,short)` | qo5 构造 | `qo5{c()=sC:site, d()=iD:timestamp}` |

**关键**：qo5=8B（site+timestamp）、cxc=12B（site+pad+
timestamp+index）——两级位置标识尺寸分层（880 vs 887）。

## `fag.n0(k3a,a)` → `o0(a,k,n,l,m,j,o)`

`k3a` 纸面配置带 **六个访问器**（k/n/l/m/j/o）——委托 `o0`
六参写器（867 登记模板+颜色高层语义；六槽细节含分层
子结构待证）。

## `j7j.c(sw9,a)` = PDF 布局写器

`k1j.c(wa0)` 资产表 + `D(8,iK,4)` 结构向量 + `zwd.a(xwd)`
元素写器 + `fa2.w`「Got negative length」日志——sw9 =
{wa0 资产 + 内联结构向量}。

## `apb.h(w,h)`/`fsi.f(l,t,r,b)` = 值类构造

`apb.h` → qed（a79.N=612×792）；`fsi.f` → vy7/fqa 四元
（a79.O=36pt 四边）。

## Harmony 侧

- `writeSequence`（qo5/cxc 形态 8B/12B 已逐字节对齐，880）。
- `builder.float32`/`writeF32` 2f/4f 结构写 ↔ qed/vy7
  布局；`originX/originY` 槽序对应。
- `k3a` 纸面 ↔ `PageBackgroundModel`（模板+颜色+分层槽）；
  `sw9` wa0+结构向量 ↔ PDF 布局编码。

## 结论

叶级写器实名：qed=8B{d,c}、vy7=16B{f,c,d,e}、qo5=8B
{site,pad,timestamp}、cxc=12B 两分层；k3a 六访问器、
sw9 资产+结构向量。纯文档+fixture 阶段。
