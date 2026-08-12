# ADR-0134：ShapeDetector 配置边界

## 状态

Accepted - Phase 157（2026-08-12）

## 背景

`ShapeDetector` 接受可选配置覆盖默认阈值。旧实现将 `NaN`、负长度、零重拟合阈值或超出
`[0,1]` 的置信度直接保存；随后会出现永不识别、除零附近拟合或无条件接受结果等不确定行为。

## 决策

- `lineThreshold`、`lineMinLength`、`ellipseMaxGap` 仅接受有限且不小于 0 的值。
- `refitThreshold` 必须有限且大于 0。
- `confidenceThreshold` 必须有限且位于 `[0,1]`。
- 非法覆盖分别回退原有默认值；有限合法覆盖保持原值，不调整原版未知的启发式判据。

## 后果

配置错误不会污染识别状态；本阶段不宣称这些启发式阈值等价于 MyScript 原版，原版识别
行为仍是独立的后续取证边界。
