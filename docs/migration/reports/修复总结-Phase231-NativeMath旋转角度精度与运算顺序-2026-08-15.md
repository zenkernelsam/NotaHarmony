# Phase 231 修复总结：Native Math 旋转角度精度与运算顺序

## 发现

Phase 230 恢复公共参数与框适配的 Float32 契约后，继续逐项反汇编 `Graphics2D_Android`，发现 rotate 的单位转换
仍与原版不同：

- MicroTeX 输入 radians，Android/Harmony Canvas 接收 degrees；
- Harmony 使用 Float32 `angle * 180 / float(π)`；
- 原版把 angle 提升为 double，执行 `angle / π * 180`，最后才回窄为 float。

一弧度时两者已相差一个 Float32 ULP；2、3、10 弧度的差异会继续扩大。该偏差会进入旋转文字、根号装饰、边框与
抗锯齿栅格化，不应因为正交角测试恰好相同就忽略。

## 原版依据

- MicroTeX `Graphics2D` 接口注释明确 rotate angle 为 radians。
- 原版 `MathDrawTarget.rotate(degrees, px, py)` 直接把 degrees 交给 Android Canvas。
- `libglmath.so Graphics2D_Android::rotate @ 0x2206e4` 明确生成：
  `fcvt s→d`、double `fdiv`、double `fmul`、`fcvt d→s`。
- 原版运算顺序是除以 π 后乘 180，不是当前 Harmony 的先乘后除。

## 修复

- 将 Harmony rotate 改为：
  `const double degrees = static_cast<double>(angle) / M_PI * 180.0;`。
- 仅在 `OH_Drawing_CanvasRotate()` 调用处把 degrees 窄化为 float。
- 保留零 pivot overload 委托三参数 overload。
- 更新 `d02-native-math-stroke-transform-fidelity.mjs`，补充 radians/degrees 契约、double 运算顺序和数值模型。
- 新增 `d02-native-math-rotation-precision.mjs`，覆盖单次窄化、禁止 float π、1/3/-3 弧度与规范角结果。
- 新增 `ADR-0208-native-math-radian-to-degree-precision.md`。

## 编译后二进制核对

default arm64 `libnota_math.so` 的 `HarmonyGraphics::rotate(float,float,float)` 已生成与原版相同的关键序列：

- `fcvt d0, s0`；
- double `fdiv d0, d0, d1`；
- double `fmul d0, d0, d1`；
- 调用 Canvas rotate 前 `fcvt s0, d0`。

旧版编译结果中的 Float32 `fmul s0` 与 `fdiv s0` 已消失。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-stroke-transform-fidelity.mjs`
- `docs/migration/replays/d02-native-math-rotation-precision.mjs`
- `docs/migration/adr/ADR-0208-native-math-radian-to-degree-precision.md`
- `docs/migration/reports/修复总结-Phase231-NativeMath旋转角度精度与运算顺序-2026-08-15.md`

## 验证

- rotation precision 专项 replay：`TOTAL=11 FAILED=0`。
- 更新后的 stroke/transform replay：`TOTAL=18 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=22 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=218 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 4 s 704 ms`。
- `note@ohosTest assembleHap`：通过，`BUILD SUCCESSFUL in 1 s 865 ms`。
- `git diff --check`：通过（仅有 Git 的 LF/CRLF 工作区提示，无空白错误）。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 使用 `\rotatebox` 或等效公式构造 1 rad、3 rad、10°、17°、33° 旋转文本并放大截图对比。
- 检查旋转细线、boxed/fbox、根号与上下标边缘是否减少一像素级跳动或灰度差。
- 同一公式连续生成与缓存命中时，确认旋转结果稳定且无纹理漂移。
- 对 90°/180° 规范角确认没有因 double 中间值引入新的偏移。
