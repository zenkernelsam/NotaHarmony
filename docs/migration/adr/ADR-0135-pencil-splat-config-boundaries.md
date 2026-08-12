# ADR-0135：PencilSplatGenerator 配置边界

## 状态

Accepted - Phase 158，2026-08-12

## 背景

原版 1.0.3 的 `xaa` 使用固定的 Pencil splat 算法常量。Harmony 侧为了测试、资源预算和宽度重算暴露了可选配置；旧实现直接覆盖默认值。`NaN`、Infinity、非正 `angleStep` 或非法 LCG 模数会污染循环和随机序列，非整数预算也会使预算语义不明确。

## 决策

- `spacing` 必须为有限正数，否则回退 2.0。
- `pressurePower`、`ellipseShrink` 接受有限且非负值，否则回退原默认值。
- `tiltNormalize` 必须有限且绝对值大于极小值，避免除零；非法值回退原默认值。
- `angleStep` 必须为有限正数；`maxSubdivisions` 必须为有限且至少 1，并取整。
- LCG multiplier 保留有限非负整数；modulus 保留有限且大于 1 的整数。
- `maximumSplatCount` 保留有限非负整数，并向下取整；非法值回退无限制默认值。
- 不改变原版 `xaa` 的散布、压力、倾角、LCG、随机顺序和输出公式。

## 证据与边界

反编译的 `xaa/ke2/fc0` 路径证明这些算法参数属于内部计算；没有证据支持修改常量或把配置清洗解释为原版 UI 行为。此阶段只防止 Harmony 调用方传入的非法数值破坏确定性。

