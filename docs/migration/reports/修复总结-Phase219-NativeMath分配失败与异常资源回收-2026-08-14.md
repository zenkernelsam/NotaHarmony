# Phase 219 修复总结：Native Math 分配失败与异常资源回收

## 发现

Phase 218 收拢 ArkTS `ImageBitmap + PixelMap` 生命周期后，继续沿原版 `s18/p18` 检查 native 绘图层，发现
`nota_math.cpp` 的失败路径仍建立在“平台分配必定成功”的假设上：

- Bitmap、Canvas、Pen、Brush、Rect、RoundRect 与字体对象存在未检查的创建结果；
- Bitmap build 后没有验证 backing pixels；
- N-API ArrayBuffer 未检查状态与指针就 `memcpy()`；
- Bitmap/Canvas 依靠成功尾部手工 destroy，draw 抛错或中途返回会绕过回收；
- 部分 Font/primitive 分配失败会继续把空对象送入 Native Drawing。

这类问题平时不一定出现，但在内存压力、损坏字体或平台对象创建失败时会直接进入 native 崩溃区，而不是像原版一样
把本次公式渲染降级为失败。

## 原版与 Harmony 适配依据

- 原版 `p18` 在 `nativeDraw()` 失败后立即 recycle 临时 Bitmap 并返回 `null`。
- 原版 `s18` 捕获 GLMath 初始化故障，将引擎标记为不可用；普通资源/公式错误不会继续击穿 App。
- Harmony Bitmap build 无返回状态，需通过 pixels 与实际尺寸验证存储是否建立。
- Harmony create API 可能返回空对象，N-API 通过 `napi_status` 报告缓冲创建结果。
- 当前 ArkTS Math consumer 已将 native `valid: false` 收敛成 `null`，适合保持原版失败降级体验。

## 修复

- 新增 `BitmapHandle` 与 `CanvasHandle` 自定义 deleter，统一调用
  `OH_Drawing_BitmapDestroy()` / `OH_Drawing_CanvasDestroy()`。
- 按 Bitmap → Canvas → `HarmonyGraphics` 声明资源，使逆序析构固定为：
  `HarmonyGraphics(Pen/Brush) → Canvas → Bitmap`。
- 移除 Render 成功尾部的手工 Canvas/Bitmap destroy，消除异常泄漏与双重释放风险。
- Bitmap 创建后立即检查对象；build 后检查：
  - pixels 非空；
  - 实际 width 等于请求 width；
  - 实际 height 等于请求 height。
- Canvas 创建失败和 `HarmonyGraphics.valid()` 失败均在 draw 前返回错误结果。
- `HarmonyGraphics` 构造器不再对空 Pen/Brush 设置属性；颜色、stroke、transform、文字、线、矩形与圆角矩形入口
  均增加所需对象门禁。
- Rect/RoundRect 分配失败安全返回；RoundRect 失败时回收已创建 Rect。
- Typeface 最终仍创建失败时，不再向 MicroTeX 暴露不完整 native Font。
- `napi_create_arraybuffer()` 同时检查 `napi_ok`、destination 与 pixels value；检查通过后才复制 RGBA bytes。
- 保留 `std::exception` 与未知异常到 `ErrorResult` 的转换，异常展开自动释放所有 scoped native 对象。
- 新增 `d02-native-math-allocation-safety.mjs`，锁定原版 recycle/降级证据、RAII 声明与析构顺序、storage
  验证、绘图资源门禁、primitive 回收、ArrayBuffer 检查及 draw 异常路径。
- 新增 `ADR-0196-native-math-allocation-failure-safety.md`。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-allocation-safety.mjs`
- `docs/migration/adr/ADR-0196-native-math-allocation-failure-safety.md`
- `docs/migration/reports/修复总结-Phase219-NativeMath分配失败与异常资源回收-2026-08-14.md`

## 验证

- Native Math 分配安全专项 replay：`TOTAL=12 FAILED=0`。
- native 数学引擎 replay：`TOTAL=7 FAILED=0`。
- 原版 Math 框适配 replay：`TOTAL=16 FAILED=0`。
- Math 位图缓存生命周期 replay：`TOTAL=12 FAILED=0`。
- 本地 Math 插入、LaTeX 编辑、consumer 与 block replay 全部通过。
- 全量桌面 replay：`REPLAY_FILES=206 FAILED=0`。
- `note@default assembleHap`：Native Ninja、PackageHap 通过，`BUILD SUCCESSFUL in 3 s 166 ms`。
- `note@ohosTest assembleHap`：OhosTest 与 native 构建链通过，`BUILD SUCCESSFUL in 289 ms`。
- `git diff --check` 通过，仅有工作区 LF 将来转换为 CRLF 的提示。
- 未启动设备、模拟器或虚拟机。

## 未闭环与真机待测

- 通过设备内存压力或故障注入验证 Bitmap、Canvas、Pen、Brush 任一 create 返回空时 App 不崩溃且公式安全留空。
- 连续渲染接近 16 MiB 上限的公式，观察 native Bitmap、ArrayBuffer、PixelMap 与 ImageBitmap 峰值和回落。
- 验证无效/缺失字体导致 Typeface fallback 失败时，measure/render 返回失败而非异常退出。
- 验证 N-API ArrayBuffer 极端分配失败时 JS 层是 `valid: false` 或 pending exception，并确保后续公式仍可恢复。
- 结合 Phase 218 的 renderer 退场测试，确认主画布与缩略图路径从 native Bitmap 到 ArkTS texture 全链路没有滞留。
