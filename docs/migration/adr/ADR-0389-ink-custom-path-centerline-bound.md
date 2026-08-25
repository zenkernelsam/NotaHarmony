# ADR-0389：显式墨迹轮廓中心线绑定

- 状态：已接受（2026-08-25）
- 场景：原版 `nwd` 的 `customPath` 是显式轮廓裁剪路径，`path` 是中心线；`e16` 对 DASH/DOTS 与实线都先 `clipPath(customPath)` 再用当前 Paint 描边中心线。Harmony 旧实现却对非虚线直接填充轮廓，对虚线才裁剪，导致 MONO/固定宽、Taper 和荧光笔的显式形状变成实心块。
- 决策：`renderCustomPath()` 对所有中心线笔迹统一构造 custom path 后 clip，再调用既有 `renderCenterPath()`。线帽、line join、DASH/DOTS 周期、backing phase 和荧光笔 alpha 覆盖继续由中心线路径统一执行。铅笔仍走 splat 专用路径，不进入该分支。
- 结果：显式轮廓只约束可见区域，不再替代中心线描边；恢复原版非自交轮廓、端点与半透明重叠语义。
