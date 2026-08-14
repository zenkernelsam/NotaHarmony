# Phase 224 修复总结：Native Math 有符号 ARGB 与数值窄化边界

## 发现

Phase 223 完成 Stroke/transform 保真后，继续逐函数核对原版 `nativeDraw` 入口，发现 Harmony 的颜色桥接
存在默认路径级别的错误：Math 默认黑色在 ArkTS、数据库和 operation 中是有符号 ARGB `-16777216`，但
Native Render 先把它读成 `double`，再直接 `static_cast<uint32_t>`。

旧版 Harmony arm64 产物在 Parse 调用前生成了 `fcvtzu w2, d1 @ 0x23c720`。这会把负色值作为无符号
浮点转换处理，默认黑色可能被钳制成 `0x00000000`，最终表现为公式透明，而不是原版的
`0xFF000000`。

同一入口还缺少 Render 逻辑宽高上限和字号上限：极大但有限的 `number` 会先参与 `ceil`，随后窄化为
`int` 或 `float`，越过已有 bitmap 分配预算之前就已经进入不安全转换。

## 原版依据

- `GLMathNative.nativeDraw` 明确接收 `int argbColor`，不是 float/double。
- `p18` 用 `int N` 保存颜色并原样传入 JNI。
- 原版 `libglmath.so nativeDraw @ 0x221bc8`：
  - `mov w19, w3 @ 0x221c00` 保存完整 `jint`；
  - `mov w2, w19 @ 0x221c28` 把同一 32 位位模式传入 `LaTeX::parse`。
- Harmony 原版兼容模型默认 Math 颜色为 `-16777216`，数据库默认值和修改回退值也保持相同约定。
- 原版详细测量使用 `100000.0f` 宽度；现有 Harmony Measure 已将 100000 与 512 作为安全上限。

## 修复

- 新增 `ReadArgb()`：
  - 只接受有限整数；
  - 有效范围为 `INT32_MIN..UINT32_MAX`；
  - 负值先转 `int32_t` 再转 `uint32_t`，复制原版 Java `int` 位模式；
  - 非负值直接按 `uint32_t` 接收，兼容 Harmony 无符号 ARGB。
- Render 的颜色局部变量改为 `uint32_t`，验证后直接传给 Parse，删除危险的
  `static_cast<uint32_t>(color)`。
- 新增并统一：
  - `MAX_LOGICAL_EDGE = 100000.0`；
  - `MAX_FONT_SIZE = 512.0`。
- Measure 改用统一常量；Render 在所有 `ceil`、`double -> int`、`double -> float` 之前拒绝超限宽高和字号。
- 新增 `d02-native-math-argb-numeric-boundary.mjs`，锁定原版 `jint` 契约、默认黑色位模式、正负 ARGB
  兼容、非法颜色拒绝及所有窄化前边界。
- 新增 `ADR-0201-native-math-signed-argb-and-numeric-boundaries.md`。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-argb-numeric-boundary.mjs`
- `docs/migration/adr/ADR-0201-native-math-signed-argb-and-numeric-boundaries.md`
- `docs/migration/reports/修复总结-Phase224-NativeMath有符号ARGB与数值窄化边界-2026-08-15.md`

## 验证

- ARGB/numeric boundary 专项 replay：`TOTAL=15 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=15 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=211 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 均通过，`BUILD SUCCESSFUL in 4 s 143 ms`。
- `note@ohosTest assembleHap`：通过，`BUILD SUCCESSFUL in 1 s 671 ms`。
- 重建后的 arm64 产物已出现独立 `ReadArgb`，负分支使用有符号 `fcvtzs`，并把已验证的 `w2` 直接传入
  `LaTeX::parse`；Render 的旧 `double color -> fcvtzu` 路径已消失。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 新插入默认黑色公式，确认不再透明，并与原版黑色及抗锯齿边缘一致。
- 分别测试半透明黑、白色、全透明以及自定义高位 alpha 颜色，确认 RGBA_8888 与预乘 alpha 的实际显示。
- 打开已有数据库中的负有符号 Math 颜色，确认历史公式无需迁移即可正确显示。
- 缩放页面并触发不同 `pixelScale` 的缓存重建，确认颜色在缓存命中与重绘路径一致。
- 对异常或损坏数据提供的小数、越界颜色和超大 Math 几何，确认安全失败而不崩溃或分配异常 bitmap。
