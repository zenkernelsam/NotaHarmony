# ADR-0201：Native Math 必须保留有符号 ARGB 位模式并在窄化前收口数值边界

## 状态

Accepted，2026-08-15。

## 问题

Harmony 的 Math 数据沿用原版 Android `int` ARGB 约定，默认黑色是 `-16777216`，其 32 位位模式为
`0xFF000000`。Native Math 的 `Render()` 却先用 `double` 接收颜色，再直接执行
`static_cast<uint32_t>(color)`。浮点数转无符号整数并不具有 Java 有符号整数转无符号位模式的模 2^32
语义；负值超出目标类型可表示范围，不能依赖该转换保留位模式。

Phase 223 生成的 arm64 `libnota_math.so` 进一步证明该写法被编译为
`fcvtzu w2, d1 @ 0x23c720`。该无符号浮点转换会把负的默认黑色钳制为 0，随后传给 `Parse()` 的就可能是
`0x00000000`，使所有默认黑色 Math 以全透明颜色绘制。

同一入口还在检查上限前把逻辑宽高经 `ceil(width * pixelScale)` 窄化为 `int`，并且 Render 未沿用
Measure 已有的字号上限。极大但有限的 JavaScript `number` 因此仍可能在 `double -> int/float` 时越界。

## 原版证据

- `GLMathNative.nativeDraw()` 的第五个业务参数是 Java `int argbColor`，JNI 描述符为
  `(Ljava/lang/String;FFFILcom/gingerlabs/notability/core/glmath/MathDrawTarget;)Z`。
- `p18` 将自己的 `int N` 原样传入 `nativeDraw(..., this.N, ...)`，没有浮点中转。
- 原版 arm64 `libglmath.so` 的 `nativeDraw @ 0x221bc8`：
  - `0x221c00: mov w19, w3` 保存 JNI 传入的 `jint`；
  - `0x221c28: mov w2, w19` 把同一 32 位位模式传给 `LaTeX::parse`。
- Harmony 的 `OriginalMathInsertPlan`、数据库默认值及原版 operation 兼容层均以 `-16777216` 表示黑色，
  因而这不是理论边界，而是默认插入公式必经的实际路径。
- 原版 `s18.e()` 使用 `100000.0f` 作为详细测量宽度；Harmony 已在 Measure 中采用同一逻辑宽度上限。

## 决策

1. 新增 `ReadArgb()`，只接受有限、无小数且位于 `INT32_MIN..UINT32_MAX` 的 JavaScript number。
2. 对负值先安全窄化为 `int32_t`，再转为 `uint32_t`，明确复制原版 `jint` 的 32 位 ARGB 位模式。
3. 对 `0..UINT32_MAX` 直接转为 `uint32_t`，兼容 Harmony 调用者可能提供的无符号 ARGB 表示。
4. Render 从入口起就以 `uint32_t color` 保存验证后的颜色，并将其直接传给 `Parse()`；禁止再次从浮点解释颜色。
5. 用 `MAX_LOGICAL_EDGE = 100000.0` 统一 Measure/Render 的逻辑尺寸边界；Render 必须在任何
   `ceil` 或 `int` 窄化前拒绝超限宽高。
6. 用 `MAX_FONT_SIZE = 512.0` 统一 Measure/Render 的字号边界，在 `double -> float` 前拒绝超限值。
7. bitmap 的 4096 单边和 16 MiB 总量预算继续作为逻辑边界之后的第二层分配保护。

## 结果

- 默认黑色 `-16777216` 稳定映射为 `0xFF000000`，不再退化为透明色。
- `-1`、`INT32_MIN` 等原版有符号颜色完整保留位模式。
- `0xFF000000`、`0xFFFFFFFF` 等 Harmony 无符号表示继续可用。
- 小数、非有限值、低于 `INT32_MIN` 或高于 `UINT32_MAX` 的颜色会失败关闭。
- 逻辑宽高和字号在所有整数/浮点窄化前有明确上限，不再依赖目标指令对越界输入的实现行为。

## 边界

- 本决策只定义 Native Math 公共入口的数值契约，不改变数据库和 operation 中继续采用的有符号 ARGB
  存储约定。
- 颜色通道的实际混合、预乘 alpha 和 Native Drawing 像素格式仍需真机逐色对比；本阶段修复的是进入
  MicroTeX 前已经丢失 32 位位模式的问题。
- 100000 与 512 是现有安全边界的显式统一，不扩张原版正常 Math 插入、测量和渲染路径。
