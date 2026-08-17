# ADR-0243：原版 Block 本地命中与 Text 裁剪语义

## 状态

Accepted - Phase 265（2026-08-17）

## 背景

M2-R-11 的既有实现已经保留 Text transform、统一层序、Clipboard、Undo 和持久化，但最终选择仍把 Text 世界 AABB
交给 `elementBoundsSelected()`：矩形只做 AABB 相交，套索只检查 AABB 中心。旋转 Text 会在真实四边形外被误选。
对象擦除虽然使用变换后四边形，却直接以 world radius 求距离，没有复刻原版非均匀 scale 下的半径换算。

进一步重放 `fu1` 发现这不是 Text 私有规则：原版所有 `oy0` Block（Text/Image/Math）都先逆变换查询到本地
`[0,size]` 再命中。`s11` 还证明 Text 绘制必须在 transform 后裁剪本地 Block size。完整证据见
`docs/migration/evidence/original-text-transform-selection-eraser-jadx-2026-08-17.md`。

## 决策

### 共享 Block 本地几何

- 新增纯逻辑 `BlockHitGeometry.ets`，集中实现 affine 验证/求逆、点命中、selection polygon 与 local rect 相交、
  eraser polyline 与扩张 local rect 相交。
- Text 传入 `[textOrigin,textOrigin+blockSize]`；Image/Math 传入 `[0,blockSize]`。不为统一实现而重写旧 Text 快照。
- 矩阵必须是有限 3×3 仿射且 determinant 非零；local size、路径点和 eraser width 也必须有限。失败统一返回 false。

### 选区和锁定

- 矩形选区转换为四点闭合路径；套索使用采样路径。逆变换后依次检查 selection 顶点、Block 四角和边交叉。
- `SelectionTool` 的 Text/Image/Math 最终判断不再读取 world AABB；Group 展开仍在命中集合形成后执行。
- positionLocked 不阻断选择，保证 Unlock 菜单可达；各几何模块的 transform/eraser 入口继续阻断锁定对象。

### 对象擦除

- eraser radius 按原版除以 Block 两轴最大 scale，再扩张本地矩形。
- Harmony 提交的是一段采样 polyline，因此除逐点命中外，连续检查相邻段与扩张矩形，避免批处理采样之间漏擦。
- 不生成 Text/Image/Math mask；whole/partial eraser 对 Block 仍是对象删除，沿用既有原子历史与持久化事务。

### Text renderer

- `Canvas2DTextRenderer` 在应用 element transform 后，以 `textBlockLocalBounds()` 建立 clip，再绘制 paper 和 RichText。
- Overlay 继续使用 `textBlockTransformComponents()` 的 world origin、signed scale 和 rotation，并在外层叠加 viewport
  zoom；不创建第二套变换来源。

## 后果

- 旋转细长 Text 的世界 AABB 空角不再造成矩形假选；套索仅穿过 Block 边缘时也能选中，不再依赖中心点。
- 非均匀缩放后的 Text/Image/Math 对象擦除半径与原版一致，不再沿短轴过度命中。
- Text highlight、glyph 和装饰不会绘制到语义 Block 外，Canvas 与固定尺寸编辑 overlay 的可见区域一致。
- Image/Math 同时消除本轮边修边审发现的相同 Block AABB/eraser 缺陷。
- 损坏 transform 不会把 NaN 传播到 selection、eraser 或编辑命中。

## 验证契约

- ArkTS fixture 覆盖 rotated quad/AABB 假阳性、矩形边交叉、lasso 边交叉、Block 包围、非均匀 scale radius、
  singular/non-finite fail-closed、Text local clip，以及 Image/Math 的共享路径。
- `d02-original-text-transform-selection-eraser.mjs` 同时读取 `be5/fu1/s11/die/ry0/td8` 和 Harmony consumer，
  并执行独立数值重放。
- Text/Image/Math/selection/renderer 相关 replay、全量 replay、`git diff --check`、clean 后两套 HAP 必须通过。

## 仍需设备验收

- 旋转、翻转、非均匀缩放 Text 的 Canvas/TextArea 边框、字体基线、padding、输入法光标和选择手柄。
- 矩形/套索边缘手感、锁定后 Unlock、Text/Image/Math whole/partial 对象擦除与 Undo/Redo。
- 50%/100%/200% zoom、保存重启、主画布/缩略图、自有包与 Notability round-trip。
- 复杂字体 fallback、RTL/shaping 与 ROUND corner 像素；没有原版证据的圆角半径继续不猜。
