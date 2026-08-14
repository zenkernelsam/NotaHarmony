# ADR-0208：Native Math 弧度转角度必须保留原版 double 运算顺序

## 状态

Accepted，2026-08-15。

## 问题

MicroTeX `Graphics2D::rotate()` 的输入单位是弧度，而原版 Android `MathDrawTarget.rotate()` 接收角度。Harmony
需要在 Native Drawing 调用前转换单位，但旧实现为：

```cpp
angle * 180.0f / static_cast<float>(M_PI)
```

这会先以 Float32 做乘法，再以 Float32 做除法；原版 arm64 port 则先把 Float32 angle 提升为 double，按
`angle / π * 180` 运算，最后只在调用 Java float 参数前窄化一次。旧实现不只是表达式写法不同，连运算顺序和中间精度
都不同。

一弧度即可复现差异：旧 float-first 结果为 `57.2957763671875`，原版结果为 `57.295780181884766`，相差一个
Float32 ULP。旋转角度最终参与文字、根号、装饰盒与边框栅格化，细线和抗锯齿边缘可能因此落在不同像素覆盖率上。

## 原版证据

- MicroTeX `graphic.h` 明确把两个 rotate overload 的 angle 标为 radians。
- `MathDrawTarget.rotate(float degrees, float px, float py)` 直接调用 Android `Canvas.rotate(degrees, px, py)`。
- 原版 arm64 `Graphics2D_Android::rotate @ 0x2206e4`：
  - `fcvt d0, s0`：Float32 angle 提升为 double；
  - `fdiv d0, d0, d3`：先除以 double π；
  - `fmul d0, d0, d3`：再乘 double 180；
  - `fcvt s0, d0`：仅在 Java float 调用边界回窄。
- 该顺序对应 `static_cast<double>(angle) / M_PI * 180.0`，而不是 float 的 `angle * 180 / π`。

## 决策

1. 在 HarmonyGraphics 三参数 rotate 中先计算：
   `const double degrees = static_cast<double>(angle) / M_PI * 180.0;`。
2. 运算顺序固定为“除 π，再乘 180”，不得重排为“先乘 180，再除 π”。
3. π 与 180 保持 double；禁止把 `M_PI` 或 180 提前转为 float。
4. 仅在 `OH_Drawing_CanvasRotate()` 的 degree 参数边界执行一次 `static_cast<float>(degrees)`。
5. 零 pivot overload 继续委托同一个三参数实现，避免两套转换公式漂移。
6. replay 固定源码表达式、单次窄化与 1/3/-3 弧度的 Float32 数值结果。
7. default arm64 构建后反汇编确认生成代码具有 `fcvt → fdiv(d) → fmul(d) → fcvt` 序列。

## 结果

- 任意 rotatebox/内部旋转装饰使用与原版相同的弧度到角度舍入结果。
- 常见非正交角度不再因 float-first 计算产生一个或多个 ULP 的偏差。
- 90°、180° 等规范角仍保持精确结果，任意角的抗锯齿位置更接近原版 Android port。
- 两个 rotate overload 共享一个精度契约，不会随维护产生分叉。

## 边界

- 相同角度数值不保证 Android Canvas 与 Harmony Native Drawing 的栅格器像素完全相同；本决策消除的是进入栅格器前
  已经存在的数值偏差。
- 极大旋转角仍由 MicroTeX 公式语义决定，本阶段不新增角度归一化，因为原版也直接转发转换后的 degrees。
- 真机仍需用非 90° 的旋转文字、boxed 与细线装饰做截图放大对比。
