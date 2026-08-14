# ADR-0204：Native Math 任一图元失败必须否决整张公式位图

## 状态

Accepted，2026-08-15。

## 问题

HarmonyGraphics 已在 TextBlob、Font、Rect 与 RoundRect 分配失败时避免空指针访问，但这些入口只是静默 return。
外层 Render 随后仍复制 bitmap pixels，并返回 `valid: true`。结果是一张缺字、缺分数线、缺边框或缺局部装饰的残缺
公式被当作完整成功结果进入 PixelMap/ImageBitmap 与缓存；后续即使内存恢复，也可能持续显示坏缓存。

这是“防崩溃但伪装成功”的半闭环。原版的公开成功单位不是单个图元，而是一次完整 `nativeDraw`：任一 Java 绘图回调
异常都会使整个 nativeDraw 返回 false，上层回收整张临时 Bitmap。

## 原版证据

- `GLMathNative.nativeDraw(...)` 只返回一个 boolean，代表整次公式绘制成功或失败。
- 原版 `MathDrawTarget` 的 drawText/drawLine/drawRect/drawRoundRect/fill 方法不在图元内部吞异常；Canvas、Typeface
  或 Paint 回调异常会留给 JNI 边界处理。
- 原版 arm64 `nativeDraw @ 0x221bc8` 在 `TeXRender::draw` 完成后调用 JNI `ExceptionCheck`：
  - 没有 pending exception 时返回 true；
  - 存在异常时执行清理并把整体返回值设为 false。
- `p18` 仅在 nativeDraw true 时返回 Bitmap；false 时立即 `bitmapCreateBitmap.recycle()` 并返回 null。

## 决策

1. HarmonyGraphics 新增 sticky `failed_` 与只读 `failed()`；一旦变为 true，本次 graphics 生命周期不可恢复为成功。
2. 空字符串绘制继续是合法 no-op，不把它误判为 TextBlob 分配失败。
3. 非空文本缺少 Canvas、Brush、HarmonyFont 或 native Font 时标记失败。
4. 非空文本的 TextBlob 创建失败时标记失败，不再静默丢字。
5. drawLine 缺少 Canvas/Pen 时标记失败。
6. drawRect/fillRect 的绘图资源或 Rect 创建失败时标记失败。
7. drawRoundRect/fillRoundRect 的绘图资源、Rect 或 RoundRect 创建失败时标记失败；已经创建的 Rect 仍先回收。
8. Render 在完整 `render->draw()` 返回后立即检查 `graphics.failed()`；失败时返回结构化错误。
9. sticky failure 检查必须发生在 ArrayBuffer 分配、memcpy 与成功结果对象构造之前。
10. 失败退出继续经过 HarmonyGraphics、Canvas、Bitmap 的作用域逆序析构，禁止保留或缓存部分 pixels。

## 结果

- 单个文字或几何图元分配失败不再伪装成完整公式成功。
- 残缺 bitmap 不会复制到 ArkTS，也不会进入 Math 位图缓存。
- 内存/资源恢复后的下一次渲染可以重新生成完整公式，不受坏缓存长期污染。
- 所有失败图元仍保持空指针安全与已分配 primitive 回收。
- 公开成功语义恢复为原版的“整次 nativeDraw 全部完成”。

## 边界

- Native Drawing 的 Attach/Draw/Detach API 多数返回 void；本层只能传播可观察的对象/字体资源失败，无法获知驱动内部
  是否真正栅格化成功。
- TextLayout 测量返回零 bounds 的路径属于布局阶段，未直接并入 graphics sticky failure；需结合设备字体故障测试判断。
- 真机仍需通过 TextBlob/Rect OOM 或故障注入确认错误能抵达 ArkTS 且缓存不会写入。
