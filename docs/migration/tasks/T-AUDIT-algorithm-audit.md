# T-AUDIT 算法审计（对照反编译源码）

## 目标

对 Phase 2/3 中所有逻辑来源于原版 Notability 反编译代码的模块进行精准审计，确保算法参数、公式、边界条件与原版一致。发现偏差则修正，无偏差则标 ✅。

## 审计原则

- **反编译源码是唯一事实来源**：任务卡伪代码与反编译代码冲突时，以反编译代码为准。
- **只改偏差，不重写**：审计是精准手术，不是推倒重来。
- **无法确认的标注为假设**：如果 reference/ 中找不到对应代码（如 `fc0.e()` 来源），标注"基于假设，待真机调参"，不强行修改。

## 第一梯队：逐方法翻译级审计（4 个文件）

### 1. ForceSmoother.ets ← ms1.java / dr4.java

| 审计点 | 原版值 | 检查内容 |
|--------|--------|----------|
| smoothing window | 8 ms | 窗口大小是否用于 force 平均/限制 |
| maxForceChange | 0.15 | 相邻点 force 变化限制 |
| enabled 默认 | true | — |
| 无压感时行为 | pressure=-1 跳过 | 不能把 -1 当成有效值参与平滑 |

### 2. CubicFitter.ets ← sqh.java / gp2.java

| 审计点 | 原版值 | 检查内容 |
|--------|--------|----------|
| 最大点数/段 | 200 | 超出截断 |
| 上下文扩展 | 前后各 5 点 | 拟合时借用相邻点，但误差验收只看目标区间 |
| 正规方程 | 2×2 Bernstein 基 | 解法是否正确（非梯度下降/非近似） |
| 病态回退 | 直线三等分控制点 | 行列式≈0 或非有限时 |
| 误差检查 | 逐点欧氏距离 | 采样步长/精度 |
| 二分分段 | 找最长可接受区间 | 不是简单对半分 |
| 容差公式 | `(0.5 / ((((dd4.d(w*z) - 2.6) / 15.4) * 1.5) + 1.0)) / z` | dd4.d() 的近似是否合理 |

### 3. WidthOutlineBuilder.ets ← w4a.java / y5a.java / hz5.java

| 审计点 | 原版行为 | 检查内容 |
|--------|----------|----------|
| 局部半宽 | `widthFactor * baseWidth / 2` | 公式是否一致 |
| 法向量计算 | 切线垂直 | 端点处理（首/末点用相邻差分） |
| 尖角处理 | 法向量突变时插入过渡 | 阈值/过渡方式 |
| 端点帽 | 半圆 | 点数/弧度 |
| 极短段 | 跳过 | 距离阈值 |
| 自交检测 | 原版是否有？ | 如果原版没有则不加 |
| 组装顺序 | 上轮廓正序 + 下轮廓逆序 + 端点帽 | 封闭路径正确性 |

### 4. PencilSplatGenerator.ets ← xaa.java / oz5.java / te6.java

| 审计点 | 原版值 | 检查内容 |
|--------|--------|----------|
| LCG | seed * 1118393071 % 1946926193 | 乘子/模数/除法精度 |
| 压感⁵ | `1 - (1 - min(p,2)/2)⁵` | 5 次方实现 |
| 倾斜 | `1 - (min((tilt-π/2)/(-0.94248), 1))⁵` | 归一化常数 |
| sizeFactor | `sizeP*sizeT + (1-sizeT)*1.0` | 组合公式 |
| scaleBase | `min(w,2)/2 * 0.97 + 0.03` | — |
| angleDiff | `max(π/5 - orientation, 0)` | — |
| splatCount | `floor(angleDiff / (π/125)) + 1` | 最多 26 |
| 椭圆 R | `1.2 * (d/2) * 0.5 * floor(...)` | — |
| 椭圆 S | `(angleDiff/(π/2)) * (-0.48) + 0.5` | — |
| 散布 x | `0.9 * cos(θ) * sqrt(u1)` | 椭圆收缩 |
| opacity | `(1-sqrt(u1)) * edgeFactor * scaleBase` | — |
| rotation | `rand * 2π` | 完全随机 |
| 等距前进 | 二分查找弧长 | 精度/迭代次数 |

## 第二梯队：参数/映射核验（5 个文件）

### 5. InkInputProviderImpl.ets ← hda.java §5

- [ ] pressure clamp [0,1]，无能力时 -1
- [ ] tilt clamp [0, π/2]，无能力时 -1
- [ ] orientation 归一化 [0, 2π)，无能力时 -1
- [ ] toolType 映射：stylus/eraser→STYLUS, mouse→MOUSE, 其他→TOUCH
- [ ] predicted event 时间戳为 0 时忽略

### 6. Canvas2DStrokeRenderer.ets ← pzf.java §4

- [ ] 实线：lineCap='round', lineJoin='round'
- [ ] DASH: setLineDash([2*width, 1*width])
- [ ] DOTS: setLineDash([0.001*width, 2*width])
- [ ] 荧光笔 alpha: 107/255 ≈ 0.42
- [ ] 空路径检查：path 为空时 return

### 7. EraserEngine.ets ← h76.java / jze §5b

- [ ] PARTIAL 使用 destination-out（等价 clipOutPath 挖洞）
- [ ] WHOLE 删除整条（不修改 maskPath）
- [ ] 碰撞检测用 bounds 相交（MVP 足够）

### 8. StrokeSession.ets ← s78.java / jv5.java §6

- [ ] pressure→widthFactor 映射：记录当前公式 `0.3 + 0.7*p`
- [ ] 标注：原版 `fc0.e()` 来源为 🟡（§35 未闭环），当前为假设值
- [ ] 笔画完成时 isFinished=true
- [ ] 取消时不产出 StrokeElementData

### 9. ShapeDetector.ets ← b90.java §24

- [ ] 直线判据：距离/跨度 > 0.6
- [ ] 直线最小长度：60px
- [ ] 直线评分提升：拟合度>0.5 且长度>60 → `(1+score)*0.5`
- [ ] 椭圆首尾距：< 120px 才检测
- [ ] 多边形：Douglas-Peucker 简化
- [ ] 置信度阈值：> 0.5 才替换
- [ ] 识别失败：返回 null，保留手画

## 产出要求

1. 对每个文件输出审计结论：`✅ 一致` / `⚠️ 偏差已修正` / `❓ 无法确认（标注假设）`
2. 修正的代码直接改（只改偏差行，不重写文件）
3. 写完成报告 `docs/migration/reports/T-AUDIT-完成.md`，包含：
   - 9 个文件逐个审计结论
   - 修正清单（改了什么、为什么）
   - 遗留假设清单（无法从 reference/ 确认的项）

## 验收标准

- [ ] 9 个文件全部有审计结论
- [ ] 修正后 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] 不修改 Phase 1 契约接口签名
- [ ] 不修改平台层代码（只改算法/逻辑层）
- [ ] 完成报告包含逐项结论

## 参考文件路径

```
reference/java/audit_cxe/cxe.java          — 画布编辑器（输入分发）
reference/java/audit_ys0/ys0.java          — 事件处理
reference/decompiled/gingerlabs/notability/ — 业务 Java（按类名查找）
docs/REVERSE_ANALYSIS.md §5/§17/§18/§23/§24/§35 — 已审计结论
```

## 完成报告

`docs/migration/reports/T-AUDIT-完成.md`
