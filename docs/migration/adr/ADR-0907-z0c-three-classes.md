# ADR-0907 — `z0c` 三归并写器类拓扑

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

65 表注册分三族：**ywd**(23 命名写器直调)、
**pee**(~31 setter/小表)、**qee**(11 合成类 switch(this.I)：
k0j.c=ud8、rr2.b=my3、qdi.a=lhe、baj.c=rl2、eaj.b=cm2、
**ys2.O=dm2**(947 实证注册项)、**haj.c=ln2**(945)、
iuh.c=dp5、fci.d=e46、kci.j=f46、yq3=占位)。

80 = 65 表 + 15 结构最终落位；命名写器与内联写器并存。

## Harmony 决策

Harmony 分派表覆盖全 80 项；yq3 抽象基注册=占位防错。

## Parity 状态

等价。

## 验证

- `d02-z0c-three-classes.mjs`：21/21 通过。
- 全量 Replay 836 文件绿，见 Phase 963 提交。
