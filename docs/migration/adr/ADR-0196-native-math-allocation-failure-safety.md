# ADR-0196：Native Math 绘图分配必须失败关闭并按作用域回收

## 状态

Accepted，2026-08-14。

## 问题

`nota_math.cpp` 的公式渲染路径原先假定 Native Drawing 与 N-API 分配一定成功：

- `OH_Drawing_BitmapCreate()`、`OH_Drawing_CanvasCreate()`、`OH_Drawing_PenCreate()` 和
  `OH_Drawing_BrushCreate()` 的返回值会直接传给后续平台 API；
- `OH_Drawing_BitmapBuild()` 后没有检查实际 pixel storage 与尺寸；
- `OH_Drawing_RectCreate()`、`OH_Drawing_RoundRectCreate()` 等 primitive 创建失败时仍可能继续绘制；
- Typeface 创建失败后仍可能把不完整 Font 暴露给文字测量与绘制；
- `napi_create_arraybuffer()` 的状态、destination 与返回 value 均未检查便执行 `memcpy()`；
- Bitmap 与 Canvas 只在成功尾部手工 destroy。`render->draw()`、ArrayBuffer 分配或后续逻辑提前返回/抛异常时，
  native 对象会泄漏。

这些路径在内存压力、字体资源异常或 Native Drawing 分配失败时可能从“公式不可用”升级为 native 空指针访问、
进程崩溃或持续资源滞留。

## 原版与平台证据

- `decompiled_1.0.3/sources/defpackage/p18.java` 在 `nativeDraw()` 返回失败时立即
  `bitmapCreateBitmap.recycle()`，随后返回 `null`；失败位图不会继续保留或绘制。
- `decompiled_1.0.3/sources/defpackage/s18.java` 捕获 GLMath 初始化异常，将引擎降级为不可用并返回失败，而不是让
  普通公式故障击穿 App。
- Harmony Native Drawing 的 create API 以空指针表示对象创建失败；Bitmap build 是 `void`，因此必须通过
  pixels 与实际宽高验证 backing storage。
- Harmony N-API 通过 `napi_status` 报告 ArrayBuffer 创建结果。未验证 destination 就复制像素会直接产生 native
  非法内存写入。
- 当前 ArkTS `OriginalMathEngine.render()` 已把 `valid: false` 结果收敛为 `null`，因此 native 失败关闭可以保持
  现有调用方降级语义。

## 决策

1. Bitmap 与 Canvas 使用 `std::unique_ptr` 加平台 destroy deleter 管理，禁止 Render 成功尾部手工 destroy。
2. 所有者声明顺序固定为 Bitmap、Canvas、`HarmonyGraphics`；C++ 逆序析构保证异常展开时先释放 Pen/Brush，
   再销毁 Canvas，最后销毁其绑定 Bitmap。
3. Bitmap object 创建失败立即返回 `valid: false`；build 后必须同时验证 pixels 非空以及实际宽高等于请求值。
4. Canvas 创建失败、Pen/Brush 任一创建失败时均不得进入 `render->draw()`。
5. `HarmonyGraphics` 的颜色、stroke、transform、文字和 primitive 绘制入口必须保护其所需的 Canvas/Pen/Brush。
6. Rect 与 RoundRect 创建失败安全返回；RoundRect 创建失败时先销毁已创建 Rect。
7. Typeface 创建失败时不向 MicroTeX 暴露可用 native Font；文字测量/绘制按现有空布局路径降级。
8. ArrayBuffer 创建必须同时满足 `napi_ok`、destination 非空和 value 非空，之后才能 `memcpy()`。
9. `render->draw()` 的标准异常和未知异常继续转换为 `ErrorResult`；作用域所有者负责异常路径清理。
10. 保持现有尺寸、16 MiB 位图预算、绘制颜色和成功结果结构不变，不借资源修复改变公式视觉算法。

## 结果

- Native Drawing 分配失败不再把空对象传入后续平台 API。
- Bitmap backing storage 或 N-API 像素缓冲分配失败时，不再执行空指针 `memcpy()`。
- `render->draw()` 抛错、任意提前返回和正常成功路径都使用同一套 native 所有权回收规则。
- 部分创建成功的 Pen/Brush、Rect/RoundRect 与 Typeface/Font 路径都有明确的安全收敛方式。
- ArkTS 调用方继续得到不可绘制公式的 `null` 降级，而不是 native 崩溃。

## 边界

- 桌面 replay 能锁定控制流与所有权结构，HAP 构建能验证 SDK 签名，但无法真正注入设备端 Native Drawing OOM。
- `OH_Drawing_CanvasBind()`、clear/scale/draw 等 API 在当前 SDK 中不返回状态；设备端驱动内部失败仍只能依靠不崩溃
  与输出检查观察。
- N-API 在极端 OOM 下可能已有 pending exception；本阶段保证不继续复制到空 destination，具体 JS 异常表现仍需
  真机压力测试。
- 真机仍需以连续大公式渲染、资源不足和页面反复进退验证 native heap 是否稳定回落。
