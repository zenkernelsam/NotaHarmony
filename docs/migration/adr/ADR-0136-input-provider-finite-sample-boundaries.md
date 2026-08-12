# ADR-0136：输入提供器有限样本边界

## 状态

Accepted - Phase 159，2026-08-12

## 背景

`InkInputProviderImpl` 将 RawPointerEvent 转为原版适配契约。旧实现只检查压力、倾角和方位角是否非负；`Infinity` 会被 clamp 为合法值，方位角归一化后还可能变成 `NaN`。非法时间戳也可能污染相对 elapsed time。

## 决策

- pressure、tilt、orientation 只有有限且非负时才进入正常 clamp/归一化；其他值统一写入能力缺失 sentinel `-1`。
- timestamp 只有有限值时才参与 elapsed time；非法时间回退 `0`。
- 不改变有限真实样本的工具类型映射、范围 clamp、历史/预测批次分类和 orientation 归一化。

## 原版/契约依据

输入审计要求能力缺失使用 `-1`，真实值才 clamp；`RawPointerEvent -> InputPoint -> StrokePathPoint/SplatAttributes` 的 sentinel 不能被非法浮点数污染。本阶段是适配边界修复，不宣称补齐设备能力探测或真实 PenKit 行为。

