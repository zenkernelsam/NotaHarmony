# Phase 149 修复总结：原版 GLMath 公式引擎 Harmony 适配

## 背景

Phase 147/148 已完成 Math 的编辑、插入、type-22/type-23 出站和持久历史，但 renderer 仍
明确是虚线矩形占位，Invalid/Ok 也只有非空与 UTF-8 预算判断。逆向 `decompiled_1.0.3` 后
确认原版 `libglmath.so` 是 MicroTeX 同源引擎，不能用普通文本绘制替代。

## 已完成修复

- 导入 MIT MicroTeX 核心源码、资源和 tinyxml2；新增独立 `nota_math` N-API shared library，
  不污染 recording native 模块。
- 使用真实 `tex::LaTeX::init/parse/TeXRender::draw`；Harmony adapter 通过 OH Native
  Drawing 字体、画布、pen/brush、TextBlob 和 bitmap 输出 RGBA pixels。
- native measure 返回真实布局宽、高、baseline；native parser 错误向上返回 Invalid，限制
  LaTeX 64 KiB、bitmap 16 MiB、边长 4096，避免原版缓存路径被恶意输入拖垮。
- `OriginalMathEngine` 从 `rawfile/glmath` 提取 73 个资源到 `filesDir/glmath`，验证路径穿越、
  文件数量和总字节预算，再初始化 native 引擎；未 ready 时不伪造成功。
- `MathCanvasRenderer` 改为 native bitmap 合成，使用 4 MiB LRU 和 PixelMap release，覆盖主画布
  与缩略图路径，删除虚线边框占位。
- Math 编辑/插入在 durable commit 前调用真实 native measure；插入自然尺寸按比例约束到原版
  240x120，解析失败保留草稿，不写入半成品状态。
- 新增 `fitOriginalMathMeasuredSize` fixture，覆盖自然尺寸比例压缩和非法尺寸拒绝。

## 验证

- `d02-native-math-engine.mjs`：`TOTAL=6 FAILED=0`。
- `note@default assembleHap`：`BUILD SUCCESSFUL`。
- `note@ohosTest assembleHap`：`BUILD SUCCESSFUL`。
- 未启动模拟器、虚拟机、真机或 Hypium。实际字体像素、复杂公式兼容性、旋转缩放和设备性能
  仍需后续设备验收，Goal 保持 active。
