# Phase 223 修复总结：Native Math 线型重放与变换 Reset 保真

## 发现

Phase 222 恢复字体来源后，继续逐函数反汇编原版 `Graphics2D_Android`，确认 Harmony 的 Stroke 和
reset 适配并非原版当前实现：

- 构造期过早把逻辑默认 Stroke 写入平台 Pen；
- `setStrokeWidth` 只更新 width，未重放 cap/join/miter；
- `reset` 清空整个 Native Canvas matrix，连 Render 入口的 `pixelScale` 也会被抹掉；
- tx/ty bookkeeping 来自旧 port，但原版 1.0.3 的 direct bridge 已不再维护它们。

## 原版依据

- `MathDrawTarget` 的 stroke Paint 构造后保持 Android 默认 width/cap/join/miter。
- `MathDrawTarget.setStroke()` 一次应用完整线型，miter 仅在正数时覆盖。
- 原版 `libglmath.so`：
  - `setStrokeWidth @ 0x220650` 更新 width 后虚调用完整 `setStroke`；
  - `translate @ 0x220674` 只转发 Canvas；
  - `scale @ 0x220698` 同步逻辑 sx/sy；
  - `reset @ 0x220730` 只把 sx/sy 写回 1。
- `LineBox::draw()` 依赖 `setStrokeWidth()` 临时修改并恢复线宽。
- `TeXRender::draw()` 在完整公式结束后 reset，而 Harmony Render 在进入 draw 前先施加 pixelScale。

## 修复

- HarmonyGraphics 构造期把 Pen 明确设为 width 0、flat cap、miter join，复刻 Android stroke Paint 默认。
- 删除构造期 `setStroke(Stroke())`，保持平台初始状态与逻辑 Stroke 分离。
- `setStrokeWidth()` 改为更新逻辑 width 后调用完整 `setStroke(stroke_)`。
- `translate()` 删除 tx/ty 伪矩阵更新，并移除成员字段。
- `reset()` 只恢复 `sx_/sy_`，不再调用 `OH_Drawing_CanvasResetMatrix()`。
- 新增 `d02-native-math-stroke-transform-fidelity.mjs`，锁定原版 Paint 默认、完整 Stroke 重放、
  cap/join 映射、positive-only miter、直接 Canvas 变换、逻辑 reset 与 pixelScale 保留。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-stroke-transform-fidelity.mjs`
- `docs/migration/adr/ADR-0200-native-math-stroke-and-reset-fidelity.md`
- `docs/migration/reports/修复总结-Phase223-NativeMath线型重放与变换Reset保真-2026-08-15.md`

## 验证

- Stroke/transform 专项 replay：`TOTAL=15 FAILED=0`。
- Native Math 分配安全专项 replay：`TOTAL=12 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=14 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=210 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 5 s 650 ms`。
- `note@ohosTest assembleHap`：OhosTest 与 native 构建链通过，`BUILD SUCCESSFUL in 2 s 332 ms`。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 对比分数线、根号横线、数组/表格线和取消线，观察线端是否由错误 round 延伸恢复为原版形态。
- 测试 boxed/fbox、圆角框和多层嵌套装饰，确认临时 width 修改后 cap/join/miter 正确恢复。
- 在 pixelScale 2 的公式 bitmap 上检查细线清晰度和尺寸，确认 reset 不再破坏外层倍率。
- 对比旋转装饰与嵌套缩放公式，确认 translate/scale/rotate 的 Native Canvas 顺序未回归。
