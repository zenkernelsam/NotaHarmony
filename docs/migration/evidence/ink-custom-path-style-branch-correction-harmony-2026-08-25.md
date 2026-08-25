# Harmony 证据：显式墨迹轮廓样式分支纠正

- 日期：2026-08-25
- Java 基准：1.0.3 `e16.java:182-253` 定义 `path10=nwd.l/customPath`；`set.contains(nwd.o)` 使用 `p16.u={DASH,DOTS}`。命中时 `clipPath(path10)` 再 `drawPath(nwd.c(), centralPathPaint)`；否则 `p16.s(fillPaint,...)` 后 `drawPath(path10, fillPaint)`。
- DEX 基准：`iw4.invoke()` fallback 显示 case 13（centralPathPaint）初始化为 ROUND cap/join 且 `Style.STROKE`；case 14（fillPaint）为 `Style.FILL`。
- 纠正：Phase 412 曾把所有样式改为 clip + stroke。现恢复 DASH/DOTS 与其他样式的原版分支，专项 Replay 改名为 style branch bound 并加强为 12/12。
- 静态验证：ArkTS 无诊断；七个相邻墨迹 Replay 全部通过。
