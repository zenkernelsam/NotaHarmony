# Phase 152 修复总结：ForceSmoother 输入边界

## 修复

- 保留原有真实时间 `dt` 加权平滑，不改变正常样本行为。
- 非有限压力（NaN/Infinity）按无压力 sentinel 处理，不进入持久化结果。
- 非法 `smoothingWindowMs`、`maxForceChange` 回退到默认值。

## 验证

`d02-force-smoother-boundaries.mjs`：`TOTAL=4 FAILED=0`。

本阶段未启动设备、模拟器、虚拟机或 Hypium；设备笔迹像素/压力曲线仍需 M2-RELEASE 验收。
