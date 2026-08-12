# ADR-0129：ForceSmoother 保留时间权重并拒绝非有限压力

日期：2026-08-12

## 决策

保留当前与原版一致的 `dt / smoothingWindowMs` 时间加权和最大变化量限制；只补输入边界：非有限压力按“无压力 sentinel”原样保留，非法窗口或变化量回到原版默认值。这样不把 NaN 写入 StrokePathPoint，也不改变正常笔迹的平滑曲线。

## 依据

`InputPoint` 契约把无压力表示为 `-1`，而 ArkTS/JSON 对 NaN 的持久化会产生不可逆的 `null`。正常有效样本仍经过原有时间加权滤波。
