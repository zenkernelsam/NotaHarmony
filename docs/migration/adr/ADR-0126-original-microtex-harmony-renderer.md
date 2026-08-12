# ADR-0126: 原版 GLMath 的 MicroTeX / Harmony Native Drawing 适配

## 状态

已采纳，2026-08-12。Phase 149 将原版 `GLMathNative.nativeMeasure/nativeDraw` 的
核心行为落到独立的 `nota_math` native shared library，不再用 ArkTS `fillText` 或虚线框
伪装 Math。

## 原版证据

- `GLMathNative` 暴露 `nativeInit(String)`, `nativeMeasure(String,float,float)` 和
  `nativeDraw(String,float,float,float,int,MathDrawTarget)`。
- `libglmath.so` 导出 `tex::LaTeX`, `TeXFormula`, `TeXParser`, `Graphics2D` 等符号，
  随包资源是 Computer Modern / AMS 字体与 XML 映射；这证明核心是 MicroTeX 同源排版引擎。
- 原版 `s18/w18` 先 measure，再 bitmap draw，并以缓存预算控制异步渲染；`g18` 将插入尺寸
  按比例约束到 240x120。

## 决策

1. 将 MIT 许可的 MicroTeX 核心源码和 tinyxml2 作为 `third_party` 源码编进独立
   `nota_math`，不依赖 Android ABI，也不链接原版私有 `.so`。
2. 用 OH Native Drawing 实现 MicroTeX `Font`, `TextLayout`, `Graphics2D`：字体使用
   `OH_Drawing_TypefaceCreateFromFile`，最终由 native bitmap 交给 ArkTS `PixelMap/ImageBitmap`。
3. ArkTS 在启动时从 `rawfile/glmath` 提取资源到 `filesDir/glmath`，native 初始化失败时保持
   未就绪状态，不把原始 LaTeX 绘成普通文本。
4. Math renderer 使用 4 MiB LRU，key 包含 LaTeX、尺寸、颜色和 pixel scale；PixelMap 淘汰时
   显式 release，符合原版 `w18` 的缓存生命周期。
5. Math Insert/Edit 在 durable commit 前调用 native measure/parse。解析失败保留 draft，成功
   后才写入 type-22/type-23 操作、更新尺寸、Undo 和 UI。

## 验证边界

- `note@default` 与 `note@ohosTest` HAP 已编译成功，native 82 个编译单元通过。
- 桌面 replay 和 ArkTS fixture 只能证明接口、预算和状态契约；尚未启动设备验证实际字体像素、
  旋转、缩放、性能和复杂公式兼容性。Goal 保持 active。
