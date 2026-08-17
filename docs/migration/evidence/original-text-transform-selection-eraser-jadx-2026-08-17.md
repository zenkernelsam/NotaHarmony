# 原版 Text/Block 变换、选区、擦除与裁剪证据（JADX，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `sources/defpackage/be5.java`：
  `46E2AC8DAAE9FCC4F1A02E18073DDA10A6417A90F2317A1175D91D56D1E410BF`
- `sources/defpackage/fu1.java`：
  `33BD30FB631C7EFFC8D282B6B07F9BB7DB37EF1B3935F4A8322B7F6A4C56206F`
- `sources/defpackage/s11.java`：
  `C3BAAAFB044F6E341C8E1588F6860CE0136B47DF2260C205269EEFD1A225480`
- `sources/defpackage/die.java`：
  `7C54E58412AF8D6012107A7C41C06107F27CE78C64C2035D5D17533836B882FD`
- `sources/defpackage/ry0.java`：
  `1018C5D3213E0E1BE4054C87661145DB8F8B39D4DCEAEDCD227AC3AE96AB2F5A`
- `sources/defpackage/td8.java`：
  `371B41FC1FBC9EF363E5B37618724E9D3F8D7961FE3B2778EB53E42103876BDB`

## 1. Block 查询先进入元素本地坐标

`be5.java:7-24` 的 `P()` 由 nullable rotation 和 scale 组成 Block 线性矩阵；Block origin 由 `h()` 独立提供，
page identity 由 `i()` 提供。`fu1.java:217-250` 随后：

1. 取得 `be5.P(null)`；
2. 调用 `y18.b(fArrP)` 求逆；
3. 平移 `-BlockOrigin-PageOrigin`；
4. 把点查询或 Path 查询映射到该本地空间。

因此 Block 的世界 AABB 只能用于粗筛或 overlay，不能作为最终选区/擦除判定。旋转细长文本的 AABB 角落并不
属于真实 Block，按 AABB 相交会产生明显假阳性。

Harmony 原版入站 Text 通常使用 `textOrigin=(0,0)` 且 transform 含 Block origin；旧 Harmony/兼容 Text 还可能
保留非零 `textOrigin`。二者的等价本地矩形分别是 `[0,size]` 与 `[textOrigin,textOrigin+size]`，所以共享命中层
必须显式接收 local bounds，不能强制改写旧快照身份。

## 2. 点/橡皮半径按最大 Block scale 换回本地单位

`fu1.java:243-245` 对 `vh5(point,radius)` 在逆变换后执行：

```java
radius / Math.max(scale.width, scale.height)
```

`fu1.java:340-352` 又在本地 `[0,width]×[0,height]` 上计算点到矩形的欧氏距离；返回世界距离时，
`fu1.java:367-371` 再乘同一个最大 scale。`fu1.java:477-490` 的布尔 Block 命中同样使用换算后的 radius，
在本地矩形四边扩张后判断。

这意味着非均匀缩放 Block 不能直接用世界空间“路径到旋转四边形距离 ≤ worldRadius”。例如 scale=(4,1) 时，
world radius 4 在原版 Block 查询中对应 local radius 1；旧 Harmony 会把沿短轴相距 3 的点误判命中。

Harmony 一次对象擦除提交持有整段采样 polyline，因此在每个原版式本地扩张矩形判定之外，还对相邻采样段执行
同一矩形相交，避免事件批处理在两点之间留下空洞；半径换算、锁定门和本地坐标仍保持原版契约。

## 3. 矩形/套索使用 Path 与真实本地矩形相交

`fu1.java:454-497` 的 `g()` 对通用 `be5` 先调用上述 `j()`。当查询是 `uh5(Path)` 且实体是 Block `oy0` 时，
原版创建本地矩形 Path：

```java
path.addRect(0, 0, blockSize.width, blockSize.height, CW)
return PathIntersects(queryPath, blockRectPath)
```

正确命中必须覆盖三种情况：

- 选区顶点进入 Block；
- Block 被选区完全包围；
- 两条边交叉但双方中心都不在对方内部。

旧 `SelectionTool.elementBoundsSelected()` 的矩形 AABB 相交与套索 AABB 中心判断都不满足该契约。新的纯几何实现
先把 selection path 逆变换到 Block 本地，再执行顶点包含、Block 角点包含和闭合边相交。奇异、非有限或非仿射
矩阵直接 fail closed，不用 NaN 继续污染选区状态。

该 `oy0` 分支是通用 Block 分支，不只属于 Text；Image 与 Math 也必须使用相同本地矩形语义。锁定 Block 仍允许
进入选区以显示 Unlock，这是 `dsc/dhb/ux9/cz3` 已确认的独立菜单语义；但 transform、文本编辑和对象擦除调用方
继续拒绝锁定实体。

## 4. Text 绘制先应用 transform，再裁剪本地 Block

`die.java:7-28/51-65` 的 `TextBlockInfo` 同时保留 transforms、textOrigin、blockScaledSize、左右/顶部 inset 和
rotation。`s11.java:102-147` 的 Text consumer 顺序明确：

1. `H(die.transforms)` 应用元素矩阵；
2. 以 `0..blockScaledSize` 建立 clip；
3. 平移 `textContentLeftInset/textContentTopInset`；
4. 绘制 RichText；
5. 在所有异常路径恢复平移、clip 和外层 Canvas 状态。

旧 Harmony 虽应用了 transform，却没有在 glyph/paper consumer 外建立 Block clip，长行、字体 highlight、下划线或
基线溢出可能画到 Block 外；编辑 TextArea 自身却有固定尺寸，造成 Canvas 与编辑态不一致。现由
`Canvas2DTextRenderer` 在 transform 后用 `textBlockLocalBounds()` clip，再进入 paper 和文本布局。

## 5. 几何不是整对象单时钟

`ry0.java:6-24/150-172` 把 page+origin、rotation、scale、size、corner、textWrap、caption、positionLocked 和
zIndex 保存为独立 register。`td8.java:243-288` 的 18-field ModifyBlock 也分别携带 origin、rotation、scale、size、
zIndex 与 positionLocked。

因此本阶段只修 consumer/命中几何，不把 transform、size 或 lock 合并成新的整对象字段，也不绕过既有 LWW、Undo、
Clipboard、持久化和原版出站链。

## 适配结论

- 新增共享纯逻辑 `BlockHitGeometry.ets`，Text/Image/Math 都复用逆仿射、Path 相交和最大 scale 半径。
- Text 本地矩形继续尊重兼容快照的 `textOrigin`；Image/Math 使用原版 `[0,size]`。
- SelectionTool 对三类 Block 不再使用 world AABB/中心点作最终判断。
- Text renderer 在本地 Block 内裁剪 paper 与 glyph；overlay 继续消费同一 origin、signed scale、rotation 和 viewport。
- 坏矩阵、坏尺寸、非有限路径与非有限 eraser width 全部 fail closed。

## 验证边界

静态 fixture/replay 可证明矩阵逆变换、旋转 AABB 假阳性、边交叉、非均匀 scale、奇异矩阵、Canvas clip 和三类
Block consumer 接线。仍需设备验证旋转/翻转 TextArea 的光标和选择手柄、复杂字体/RTL shaping、不同 zoom 的像素
重合、Image/Math 旋转选区与对象擦除手感，以及保存重启/Undo/Notability round-trip。ROUND Text corner 的原版像素
半径仍无静态证据，本阶段继续不猜。
