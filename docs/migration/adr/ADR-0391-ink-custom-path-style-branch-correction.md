# ADR-0391：显式墨迹轮廓样式分支纠正

- 状态：已接受（2026-08-25）
- 场景：ADR-0389 将 `customPath` 一律作为中心线裁剪，误读了原版分支。1.0.3 `e16.java` 中只有 `p16.u = {DASH,DOTS}` 才执行 `clipPath(customPath)` 后绘制中心线；非虚线样式在 else 分支用 `p16.k()`（fillPaint）绘制 customPath。DEX fallback 进一步证明 fillPaint 初始化为 `Style.FILL`，centralPathPaint 为 `Style.STROKE`。
- 决策：恢复按样式分流——DASH/DOTS 走 customPath 裁剪加中心线描边；VARIABLE_WIDTH、FIXED_WIDTH 和荧光笔的显式轮廓直接填充，并保留荧光笔 107 alpha。铅笔 splat 分支继续独立处理。
- 结果：修正 Phase 412 引入的非虚线回归，同时保留 DASH/DOTS 的裁剪语义和统一 dash 参数/相位契约。
