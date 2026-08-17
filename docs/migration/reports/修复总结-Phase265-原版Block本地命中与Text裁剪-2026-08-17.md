# Phase 265 修复总结：原版 Block 本地命中与 Text 裁剪

## 基线与目标

- 基线提交：`977fe31 fix(shape): preserve original semantic rendering`
- 目标：继续重放 `修复总纲2.md` 的 M2-R-11，严格参考原版 1.0.3 的 Block 变换、点/Path 命中、擦除半径与
  Text consumer，修复 Text 变换后的选区、对象擦除和 Canvas 裁剪；边修边审同类 Image/Math Block。
- 本阶段不启动设备、模拟器、虚拟机、真机或 Hypium。

## 原版证据结论

- `be5` 由独立 origin、rotation、scale 和 page identity 组成 Block 世界变换。
- `fu1.j()` 先求 Block 线性矩阵逆，再平移 `-BlockOrigin-PageOrigin`，把点或 Path 查询映射到 Block 本地空间。
- `fu1` 的 Block 点半径除以两轴最大 scale；`g()` 对 `oy0` 使用本地 `[0,size]` 矩形，而不是世界 AABB。
- `s11` 在应用 Text transform 后先裁剪 `0..blockScaledSize`，再平移内容 inset 并绘制 RichText。
- `ry0/td8` 将 origin、rotation、scale、size、lock 与 z-index 保持为独立 register；本阶段不能另造整对象时钟。

完整哈希、行号、片段和兼容边界见
`docs/migration/evidence/original-text-transform-selection-eraser-jadx-2026-08-17.md`。

## 修复前真实缺陷

### 旋转 Block 仍按世界 AABB/中心选择

`SelectionTool` 对 Text/Image/Math 的矩形选区只做 world AABB 相交，套索只判断 AABB 中心。旋转细长 Text 的
AABB 空角会产生假阳性；套索只穿过真实 Block 边缘但不含中心时又会漏选。

### 非均匀缩放后的对象擦除半径错误

旧实现直接计算 world polyline 到变换后四边形的距离。原版会把查询半径除以最大 Block scale 后再进入本地矩形；
scale=(4,1) 时，旧实现会沿短轴过度命中。

### Text Canvas 没有本地 Block clip

旧 renderer 已应用 transform 和 inset，却没有限制 paper、highlight、glyph 与装饰的可见区域。长行或大字体可能
画出固定尺寸 TextArea，而编辑 overlay 自身仍被尺寸裁剪，造成显示态与编辑态不一致。

## 实际修改

### 共享 Block 本地几何

- 新增纯逻辑 `BlockHitGeometry.ets`，集中实现有限仿射校验/求逆、点命中、selection polygon 与 local rect 相交、
  eraser polyline 与扩张 local rect 相交。
- 选区依次覆盖选区顶点进入 Block、Block 四角被选区包围和双方边交叉；不再依赖任一 AABB 中心。
- singular、非仿射、NaN/Infinity、坏尺寸、坏路径和非法 eraser width 全部 fail closed。
- eraser radius 使用 `eraserWidth / 2 / max(scaleX,scaleY)`；连续采样段继续检查与扩张矩形相交，避免批处理点间漏擦。

### Text/Image/Math consumer

- Text 使用兼容本地矩形 `[textOrigin,textOrigin+blockSize]`；Image/Math 使用原版 `[0,blockSize]`。
- 三类 Block 的 SelectionTool 最终命中统一进入共享逆变换几何。
- positionLocked Block 仍可进入选区，以保持 Unlock 菜单可达；transform、编辑和对象擦除入口继续拒绝锁定实体。
- Group 展开仍在叶实体命中集合形成后执行，未改变原版 group identity/层序语义。

### Text renderer

- `Canvas2DTextRenderer` 在应用 element transform 后，以 `textBlockLocalBounds()` 建立 clip，再绘制 paper 和
  RichText。
- Text overlay 继续消费 `textBlockTransformComponents()` 的 world origin、signed scale、rotation，并叠加
  viewport zoom；没有引入平行坐标模型。

## 边修边审发现并修复

- 原版 `fu1` 的 `oy0` 分支是通用 Block 规则，不只属于 Text；Image/Math 的同类 AABB/世界半径缺陷因此一并修复。
- 四份旧 replay 仍断言 SelectionTool 使用 AABB，已更新为共享本地几何契约；锁定对象可选择但不可修改的门禁继续
  独立验证。
- 第一轮静态 fixture 只覆盖点落入矩形；现增加“选区与 Block 只发生边交叉、双方中心均不被包含”的 lasso 场景。
- 增加 singular/NaN fail-closed 与 Text highlight/glyph 越过 blockHeight 时的 clip fixture，防止几何错误退化为
  随机选择或 Canvas 状态污染。

## 主要修改范围

- 几何：新增 `BlockHitGeometry.ets`，更新 `TextBlockGeometry.ets`、`ImageBlockGeometry.ets`、
  `MathBlockGeometry.ets`
- consumer：`SelectionTool.ets`、`Canvas2DTextRenderer.ets`
- 测试：`TextBlockGeometry.test.ets`、`SelectionTool.test.ets`、`ImageBlockRendering.test.ets`、
  `MathBlockGeometry.test.ets`、`RendererStyle.test.ets`
- 文档/重放：ADR-0243、原版 JADX evidence、新专项 replay，并更新四份旧静态 replay

## Replay 与构建验证

- `d02-original-text-transform-selection-eraser.mjs`：`TOTAL=25 FAILED=0`
- Text/Image/Math/Selection/Renderer 相关 replay：`RELATED_REPLAY_FILES=16 FAILED=0`
- 全量桌面 replay：`REPLAY_FILES=250 FAILED=0`
- 使用 `C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat`，同一次 clean 后严格串行：
  - clean：`BUILD SUCCESSFUL in 4 s 989 ms`
  - `note@ohosTest`：`BUILD SUCCESSFUL in 10 s 26 ms`
  - `note@default`：`BUILD SUCCESSFUL in 35 s 487 ms`
- 构建只有项目既有 ArkTS/deprecation 与未配置 signing warning。`ohosTest` 只证明 fixture 源码完成 ArkTS
  编译/打包，不冒充设备执行 Hypium assertion。
- `git diff --check`：通过，仅有工作树 LF→CRLF 提示。

## M2-R-11 状态与设备验收

M2-R-11 已知静态 Block transform 命中、SelectionTool、对象擦除半径与 Text Canvas clip 项现闭环。仍需设备验证：

- 旋转、翻转和非均匀缩放 Text 的 Canvas/TextArea 边框、字体基线、padding、输入法光标与选择手柄；
- 矩形/套索边缘手感、positionLocked Unlock、Text/Image/Math whole/partial 对象擦除与 Undo/Redo；
- 50%/100%/200% zoom、保存重启、主画布/缩略图、自有包与 Notability round-trip；
- 复杂字体 fallback、RTL/shaping 与 ROUND corner 像素。没有原版证据的圆角半径继续不猜。

## Goal 纪律

T-042 APK 版本追踪继续严格留到整个 Goal 最后。本阶段只登记延后约束，不创建版本追踪目录、不执行整包版本
diff；最终必须另写中文 Report，并把追踪文档/工具的用途、入口、阅读顺序和新版 APK decompile/diff 流程归纳进
Wiki、技术文档、API 文档与新手入门。
