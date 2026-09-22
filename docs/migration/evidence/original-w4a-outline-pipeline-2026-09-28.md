# 原版可变宽度轮廓管线解码（w4a / y5a / lqh / b2j，2026-09-28）

阶段：Phase 579。对象：审计注册表挂起的 `w4a.java`（可变宽度轮廓）。
注意：审计引用的是 **1.0.1** 混淆表 —— 1.0.3 的 `w4a` 是无关的
synthetic switchmap；真正的轮廓类在 `decompiled_1.0.1/sources/
defpackage/w4a.java`（947 行，完整反编译）。

## 1. `w4a.a(xw0, d2)` —— 累积距离简化

逐组件遍历 `i4a`，累加相邻点段长（`w76.l0` = hypot），累计 ≥ `d2`
才保留下一点。调用点：

- `y5a.n` 建轮廓前：`w4a.a(..., 0.0)` —— d2=0 时首段即触发，实际为
  规范化（不丢点）。
- `lqh.b` / `b2j` 轮廓产出后：`w4a.a(..., 0.1)` —— 输出轮廓按 0.1
  最小跨度抽稀。

Harmony 对应：`WidthOutlineBuilder.removeDegenerateSamples` 以
`MIN_SEGMENT_LENGTH=1e-4` 合并近重复样本并保留较大 widthFactor
（压感峰不丢）。语义为超集：原版按累计跨度抽稀，Harmony 只合并
近重复点、输出更密（更平滑）。

## 2. `w4a.b(xw0, scale)` —— 轮廓生成器

- **退化分支**：组件恰为 1 元素 1 点（`og8.b==1 && f(0)==1`）且
  首末宽度属性相等、首尾点距 ≤ 1e-4 → 发出 `z71(r,0,0,r,x,y)` 圆，
  半径 `widthAttr · 0.5 · globalScale · componentScale`。
  Harmony `buildDegenerateCircle(pos, widthFactor·baseWidth/2)` ——
  语义一致。
- **宽度链**（与 Phase 269 移植常量逐字一致）：元素弦长下限 1e-6；
  PCHIP 导数 `3(h1+h2)/((2h1+h2)/m2 + (2h2+h1)/m1)`（`f92.c` 即
  `(d·a+b)/c` 线性映射）；`oki.a={0.25,0.5,0.75}` 偏差探针；
  `dMax·1.2` 安全系数；`max(maxW,0.05)·0.005` 容差；细分
  `ceil(sqrt(dev/tol))` 钳制 2..6。
- **轮廓装配**（约 340 行，`??` 破型部分）：按 `o4a` 区间切分
  （`ic0Var3.p(i)` 位置映射 + 相邻区间合并），再经 `jc0` 装配。
  几何细节在 JADX 层不可完整还原 —— 见第 4 节遗留。

## 3. `y5a.n` —— 渲染入口分派

- `sz5.DASH/DOTS` → `w4a.a(...,0).r()` 直接取**中心线** Path（描边
  渲染，Phase 574 `c5g/e16` 已证 DashPathEffect 相位恒 0）。
- 实心 → `w4a.b(...,strokeScale).r()` 填充轮廓，再 `offset` 到视口
  原点，`aqi.b` 求包围盒。

Harmony：`renderCenterPath`（虚线描边）vs 填充轮廓 —— 已对齐。

## 4. `lqh.b` —— 擦除轮廓自交策略（有意发散）

原版：轮廓 → `w4a.a(0.1)` 抽稀 → `b2j.a` 自交检查（`cp2.b` 标志）
→ 不自交才接受；否则 `splitAtMiddleElement` **递归二分**组件再
分别建轮廓（>10 点且包围盒周长超限才走二分）。

Harmony：`OriginalInkPartialEraser` 用 `drawing.Path.op` 原生布尔
运算，自交由 fill-rule 天然消解 —— 机制不同、能力严格更强，记录为
有意发散（ADR-0550），不改。

## 5. 遗留（不可静态还原部分）

`w4a.b` 的 offset 弧/内部弧装配几何含 `??` 破型，JADX 层不可逐行
还原；按 M2-A-09 决策门，最终轮廓保持 ADR-0002 自适应展平+圆弧
外接头近似。本阶段关闭 `w4a` 审计中可验证的全部语义半区
（简化策略、退化圆、宽度链常量、渲染分派、擦除自交策略），
装配几何差异继续挂起待字节码级证据。

回放：`d02-original-w4a-outline-audit.mjs`（12/12）。
