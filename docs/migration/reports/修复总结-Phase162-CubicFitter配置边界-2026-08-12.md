# Phase 162 修复总结：CubicFitter 配置边界

## 发现

`CubicFitter` 的三个构造配置可被 NaN、无穷、小数或非法负值覆盖。分段上限异常时可能导致分段循环不前进，上下文扩展异常时可能产生非法索引，基础容差异常时会破坏原版拟合边界。

## 修改

- `note/src/main/ets/core/algorithm/CubicFitter.ets`
- 新增 `ADR-0139-cubic-fitter-config-boundaries.md`
- 新增 `d02-cubic-fitter-config-boundaries.mjs`

仅增加配置输入校验，保留原版默认值和动态容差公式：`200 / 5 / 0.5`；合法覆盖分别要求整数 `>=2`、整数 `>=0`、有限正数。

## 验证

- Replay：`TOTAL=5 FAILED=0`
- `note@default assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- `note@ohosTest assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- 未启动设备、模拟器、虚拟机或 Hypium。

## 未闭环

真实笔迹样本的拟合误差和分段视觉结果仍需设备/截图回归；本阶段不宣称运行态完成。
