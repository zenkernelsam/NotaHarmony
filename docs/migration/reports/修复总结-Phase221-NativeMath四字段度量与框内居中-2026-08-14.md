# Phase 221 修复总结：Native Math 四字段度量与框内居中

## 发现

Phase 220 恢复字体样式和 baseline 文本度量后，继续反汇编 Notability 1.0.3 的 arm64
`libglmath.so`，确认 Harmony 的 `nativeMeasure/nativeDraw` 仍没有完全遵守原版协议：

- parse width 使用 `ceil` 而不是原版向零截断；
- line spacing 为 `4.0f` 而不是原版 `0.0f`；
- `getHeight()` 已是公式总高，Harmony 却再次加上 `getDepth()`，导致拟合高度被高估；
- depth 没有作为第四个测量字段发布；
- 公式固定绘制在 block 左上角，缺少原版横纵整数居中。

## 原版依据

- `n18.java`：`MathMetrics(widthPx, heightPx, baselineFraction, depthPx)`。
- `s18.e()`：按 native 数组的前四项构造详细度量；`s18.d()` 只以 width/height 计算拟合比例。
- `p18.java`：bitmap 像素尺寸使用 `ceil(block * scale)`，`nativeDraw` 接收未像素化的逻辑 block 尺寸。
- `libglmath.so`：
  - `nativeMeasure @ 0x221990` 使用 `fcvtzs` 截断宽度，传入 `0.0f` line spacing，并依次取
    `getWidth/getHeight/getBaseline/getDepth`；
  - `nativeDraw @ 0x221bc8` 仅在公式小于 block 时计算 `int(gap) / 2`，随后以该 x/y 绘制。

## 修复

- 将 parse line spacing 改为 `ORIGINAL_LINE_SPACE = 0.0f`。
- 测量和绘制的 parse width 改为 `static_cast<int>(width)`。
- 保留 bitmap 分配的 `ceil(width * pixelScale)` / `ceil(height * pixelScale)`，避免误改原版外层规则。
- `MathMeasureResult` 新增 `depth?: number`。
- native measure 恢复四字段：
  - width：`render->getWidth()`；
  - height：`render->getHeight()`；
  - baseline：`render->getBaseline()`；
  - depth：`render->getDepth()`。
- 删除错误的 `getHeight() + getDepth()`。
- native draw 恢复原版横纵居中，并在公式不小于 block 时把对应偏移钳制为 0。
- 更新分配安全 replay，使其继续验证资源门禁发生在新的偏移绘制之前。
- 新增 `d02-native-math-metrics-centering.mjs`，锁定 Java 协议、native 适配、四字段接口、截断规则、
  零行距、非负居中及运行时整数模型。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `note/src/main/cpp/types/libnota_math/Index.d.ts`
- `docs/migration/replays/d02-native-math-allocation-safety.mjs`
- `docs/migration/replays/d02-native-math-metrics-centering.mjs`
- `docs/migration/adr/ADR-0198-native-math-metrics-and-block-centering.md`
- `docs/migration/reports/修复总结-Phase221-NativeMath四字段度量与框内居中-2026-08-14.md`

## 验证

- 四字段度量与框内居中专项 replay：`TOTAL=15 FAILED=0`。
- Native Math 分配安全专项 replay：`TOTAL=12 FAILED=0`。
- Native Math 字体保真专项 replay：`TOTAL=12 FAILED=0`。
- 原版 Math 框适配专项 replay：`TOTAL=16 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=208 FAILED=0`。
- `note@default assembleHap`：Native Ninja、ArkTS、PackageHap 通过，`BUILD SUCCESSFUL in 16 s 781 ms`。
- `note@ohosTest assembleHap`：OhosTest ArkTS、native 与 PackageHap 通过，`BUILD SUCCESSFUL in 7 s 294 ms`。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 边修边审的新发现

`Font::_create(const std::string &name, ...)` 当前忽略 `name`。原版 `Font_Android` 会保留该字符串，
`lz4` 会先把非空值当作字体文件加载，失败后才按 style 回退默认 Typeface；因此自定义 text font/path 当前不会生效，
而 `Serif`、`SansSerif` 等字体身份也可能被错误合并。该问题独立进入 Phase 222，避免与本阶段度量协议混修。

## 真机待测

- 在大 block 内输入短公式，确认横纵留白与原版一致且不再贴左上角。
- 对比分数、根号、上下标、含 descender 的 text 公式，确认拟合字号不再因 depth 重复计算而偏小。
- 使用带小数的窄 block 和多行公式，确认换行边界与 0 行距接近原版。
- 测试公式大于 block 的保护路径，确认从原点绘制且不会出现负偏移或 native 崩溃。
