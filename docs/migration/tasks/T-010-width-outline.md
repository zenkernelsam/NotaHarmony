# T-010 可变宽度轮廓算法

## 目标

实现中心线 → 填充轮廓的完整算法（对应 `w4a.b()`），支持逐点 widthFactor 生成封闭多边形路径。一步到位，不允许降级。

## 参考

- 知识库：REVERSE_ANALYSIS.md §23（w4a.b() 主体：读取 fc0.e() 逐点宽度，widthFactor * baseWidth / 2 = 局部半宽）、§35（审计结论：Taper/任何 fc0.e()!=1 都进入此路径）
- 反编译源码：`reference/decompiled/gingerlabs/notability/` 中相关类（w4a/y5a/hz5）
- 契约：`note/src/main/ets/core/model/GeometryTypes.ets`（Point2D）
- 契约：`note/src/main/ets/core/model/StrokeTypes.ets`（StrokePathPoint）

## 实现要求

### 创建文件

`note/src/main/ets/core/algorithm/WidthOutlineBuilder.ets`

### 接口设计

```typescript
import { Point2D } from '../model/GeometryTypes';
import { StrokePathPoint } from '../model/StrokeTypes';

export interface OutlineResult {
  // 封闭轮廓点序列（可直接用 Canvas path moveTo/lineTo/closePath 绘制）
  outlinePoints: Point2D[];
  // 是否为有效轮廓（点数 >= 3）
  isValid: boolean;
}

export class WidthOutlineBuilder {
  // 主入口：从中心线 + 逐点宽度生成填充轮廓
  build(centerline: StrokePathPoint[], baseWidth: number): OutlineResult {
    // 见下方算法步骤
  }

  // 计算每个点的法向量（垂直于切线）
  private computeNormals(points: StrokePathPoint[]): Point2D[] {
    // 对点 i：切线 = normalize(points[i+1] - points[i-1])
    // 法向量 = (-tangent.y, tangent.x)
    // 端点：用相邻两点差分
  }

  // 生成上/下轮廓线
  private offsetCurve(points: StrokePathPoint[], normals: Point2D[], baseWidth: number, sign: number): Point2D[] {
    // 对每个点 i:
    //   halfWidth = points[i].widthFactor * baseWidth / 2
    //   offset[i] = centerline[i] + normal[i] * halfWidth * sign
  }

  // 端点半圆帽
  private buildRoundCap(center: Point2D, normal: Point2D, halfWidth: number, startAngle: number): Point2D[] {
    // 生成 4-6 个点的半圆弧
  }

  // 尖角处理：相邻法向量夹角 > 阈值时插入扇形过渡
  private handleSharpCorners(upper: Point2D[], lower: Point2D[], normals: Point2D[]): void {
    // 如果 dot(normal[i], normal[i+1]) < cos(60°) → 插入中间过渡点
  }
}
```

### 算法步骤（工人必须按此实现）

1. **输入验证**：centerline.length < 2 → 返回 `{ outlinePoints: [], isValid: false }`
2. **计算法向量**：对每个中心线点计算垂直于切线方向的单位法向量
3. **上轮廓**：centerline[i] + normal[i] × (widthFactor[i] × baseWidth / 2)
4. **下轮廓**：centerline[i] - normal[i] × (widthFactor[i] × baseWidth / 2)
5. **起点帽**：在 centerline[0] 处生成半圆连接上轮廓起点和下轮廓起点
6. **终点帽**：在 centerline[n-1] 处生成半圆连接上轮廓终点和下轮廓终点
7. **尖角处理**：检测相邻法向量突变，插入过渡点避免自交
8. **组装**：outlinePoints = 起点帽 + 上轮廓正序 + 终点帽 + 下轮廓逆序
9. **输出**：封闭多边形（调用方 closePath）

### 鸿蒙特有约束

- **禁止** import 任何 `@ohos.*` / `@kit.*`（纯数学模块）。
- 所有向量运算手动实现（无第三方数学库）。
- widthFactor = 1.0 时等价于固定宽度（轮廓为等宽带状）。
- widthFactor 从 1.0 渐变到 0.0 时产生 Taper 收笔效果。
- 极短段（两点距离 < 0.01）跳过法向量计算，用前一个法向量。

## 验收标准

- [ ] 文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] 等宽输入（widthFactor=1）产生矩形带状轮廓
- [ ] Taper 输入（widthFactor 从 1→0）产生尖端收笔
- [ ] 2 点输入产生有效轮廓（两个半圆帽）
- [ ] 无平台 import
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-010-完成.md`
