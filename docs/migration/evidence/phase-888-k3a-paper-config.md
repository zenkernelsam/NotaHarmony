# Phase 888 证据 — `k3a` 纸面配置六字段与 `fag` 工厂

## 目的

登记 887 遗留的 `k3a` 六访问器细节：`fag.o0` 字段写器 +
`fag.k` 工厂 + `tu1`/`cmf`/`n3a` 值（`decompiled_1.0.3`）。

## `fag.o0` = `k3a` 六字段写器（实证）

`o0(a, n3a, Float, Boolean, Boolean, hu1, cmf)` → `C(6)`：

| 字段 | 类型 | 写器 | 语义 |
|------|------|------|------|
| 0 | `n3a.I` | `c(0,I,0)` | **纸面模板枚举**（n3a：LINES=0/DOTS=1/GRID=2） |
| 1 | `Float` | `d(1,f,0.0)` | 间距/尺寸 |
| 2 | `Boolean` | `a(2,b,false)` | 标志位（aVar.l=true/false 包裹两布尔写——builder 写模式标记） |
| 3 | `Boolean` | `a(3,b,false)` | 标志位 |
| 4 | `hu1` | `j(4,z5c.P)` | **纸色**（4B 颜色结构） |
| 5 | `cmf.I` | `c(5,I,0)` | cmf 字节枚举（纸面相关第二枚举） |

`o0` 内 `aVar.l = true; ...bool 写...; aVar.l = false`——
布尔字段写期间的 builder 模式标记（登记留档）。

## `fag.k` = `k3a` 工厂（存根）

`a79.Q` 实传 `fag.k(null,null,null,(hu1)tu1.a.getValue(),
null, 111)`：掩码 111 = bit0+1+2+5+6——默认 n3a/Float/Bool
+ param5/6，仅 hu1 色显式、cmf 显式 null。→ 默认纸 =
「模板/间距/标志全默认 + tu1 色」。

## `tu1`/`cmf`/`n3a` 值层

- `tu1.a` = `pce`（cx6 惰性提供者，`ra(13)` 初始化）→
  默认纸色 `hu1`；`tu1.a(r,g,b,a)`/`c(int)`/`d(Color)` =
  hu1 构造族；`ra` 颜色映射含白/黑/红/蓝基础项。
- `cmf` = `{I:byte}` 字节值类枚举（`a(I)` 格式化）。
- `n3a` = `LINES=0/DOTS=1/GRID=2`（867 已登）。

## Harmony 侧

- `PageBackgroundModel`/paper 编码 ↔ k3a 六槽（模板/间距/
  标志×2/颜色/枚举）；`validateOriginalPaper` 同界。
- `hu1` 4B 色 ↔ Harmony 颜色结构写；`tu1` 默认色 ↔
  默认纸配置。

## 结论

k3a 六槽线格式实名（模板+间距+双标志+色+枚举）；fag.k
掩码 111 第三例证「高位=省略参数序号」。纯文档+fixture
阶段。
