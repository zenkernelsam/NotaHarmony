# Phase 230 修复总结：原版 Math Float32 框适配与 Native 参数

## 发现

Phase 229 封闭 PixelMap alpha 契约后，继续逐函数对照 `s18/p18/GLMathNative` 与原版 arm64
`libglmath.so`，发现现有 Math 自适应虽然复制了 floor/max/min/floor/ceil 的公式，却没有复制其 Float32 执行语义：

- 原版框宽高、测量结果、比例、字号、density scale 与 JNI 参数全部是 float；
- Harmony ArkTS 默认以 double 做除法和乘法；
- Native 入口也先保存 double，bitmap sizing、居中与 Canvas scale 未统一窄化；
- fitted 结果额外要求不超过框宽高，原版并不存在该硬门。

这会造成真实逻辑错误：`27×55` 框配合 `126×319` 测量时，double 乘积略大于 55，ceil 为 56，旧实现随后
返回 `null`；原版 Float32 结果为 55，应成功。另一组 `240×81 / 852×133` 则会在原版得到 241px 宽度，属于合法的
单像素 Float32 ceil overshoot。

## 原版依据

- `GLMathNative` 的 measure/draw 几何和字号参数均为 Java float。
- `s18.d()` 的 box、measurement、ratio 与 fitted 字段均为 float，每次除法/乘法都会发生 binary32 舍入。
- `p18` 用 float block size × float density 计算 bitmap 尺寸。
- 原版 arm64 nativeMeasure/nativeDraw 从 `s` 寄存器读取参数，并以 Float32 完成 parse 截断、宽高比较、差值与居中。
- `vc case 27` 和 `g18` 直接消费 `q18 -> SizeF`，没有对 240/120 再做绝对上限拒绝。

## 修复

- `originalMathMeasurementFontSize()` 在 floor/max 前先 `Math.fround()` box width/height。
- `fitOriginalMathMeasuredSizeToBox()` 对以下每个原版 float 边界逐步 `Math.fround()`：
  - measured width/height；
  - width ratio 与 height ratio；
  - min scale；
  - font size、fitted width、fitted height 的乘积。
- fitted 宽高允许最多比 floor 后的对应框轴大 1px；超过 1px 仍 fail closed。
- Math 插入 draft 允许 `240×120` 最大框出现同样的单像素原版舍入结果，242/122 及更大结果继续拒绝。
- Native 新增 `ReadPositiveFloat()`，把 N-API number 在安全边界内统一窄化并验证为正有限 float。
- Measure 从入口起以 float 保存 width/font size。
- Render 从入口起以 float 保存 width/height/font size/pixelScale；bitmap ceil、parse、居中和 Canvas scale 共用这些值。
- 更新 box-fit、metrics/centering、ARGB/numeric 三条既有 replay。
- 新增 `d02-original-math-float32-contract.mjs` 与 ArkTS fixture，锁定精确贴轴和 1px overshoot 两类回归。
- 新增 `ADR-0207-original-math-float32-fit-and-native-arguments.md`。

## 边修边审排除项

曾怀疑 `HarmonyTextLayout::getBounds()` 在字体测量失败时把 bounds 清零会伪装成功。原版
`TextLayout_Android::getBounds @ 0x220db8` 的反汇编显示它先将四字段清零；Java measure 返回 null 时检查并清除
JNI 异常，然后保留零 bounds 返回。因此当前零 fallback 与原版一致，本阶段没有误改为抛异常。

## 修改文件

- `note/src/main/ets/core/model/OriginalMathInsertPlan.ets`
- `note/src/main/cpp/nota_math.cpp`
- `note/src/test/OriginalMathInsertPlan.test.ets`
- `docs/migration/replays/d02-original-math-box-fit.mjs`
- `docs/migration/replays/d02-native-math-metrics-centering.mjs`
- `docs/migration/replays/d02-native-math-argb-numeric-boundary.mjs`
- `docs/migration/replays/d02-original-math-float32-contract.mjs`
- `docs/migration/adr/ADR-0207-original-math-float32-fit-and-native-arguments.md`
- `docs/migration/reports/修复总结-Phase230-原版Math-Float32框适配与Native参数-2026-08-15.md`

## 验证

- Float32 contract 专项 replay：`TOTAL=14 FAILED=0`。
- 更新后的原版 Math box-fit replay：`TOTAL=18 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=21 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=217 FAILED=0`。
- `note@default assembleHap`：Native Ninja、ArkTS 与 PackageHap 通过，`BUILD SUCCESSFUL in 11 s 168 ms`。
- `note@ohosTest assembleHap`：测试 ArkTS 与 PackageHap 通过，`BUILD SUCCESSFUL in 6 s 995 ms`。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 构造宽或高恰好贴合 block 的长分式、矩阵和多行公式，确认不再偶发插入/编辑无响应。
- 检查新插入公式是否偶尔出现 241×N 或 N×121 的原版舍入尺寸，并确认选区、缓存与绘制均正常。
- 对同一 LaTeX 连续执行 fit/render，确认 Float32 结果稳定且缓存 key 不发生抖动。
- 对小数 block 尺寸和 bitmap scale 做原版截图比较，核对一像素边界、居中和裁切。后续 Phase 236 已确认
  standalone Math 的原版 scale 不是固定 2×，而是 `zoom × Density` 经 1–4 clamp 和 0.5 步长量化。
