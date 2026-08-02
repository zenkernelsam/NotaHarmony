# T-009 Force Smoother + 三次贝塞尔拟合

## 目标

实现两个纯数学算法模块：力平滑器（限制 pressure 突变）和三次贝塞尔曲线拟合器（最小二乘 + 动态容差 + 二分分段）。

## 参考

- 知识库：REVERSE_ANALYSIS.md §17（完整算法：ms1/dr4/sqh/gp2，Force smoothing 参数 8ms/0.15，拟合 200 点上限，上下文 5 点，容差公式）
- 契约：`note/src/main/ets/core/model/GeometryTypes.ets`（Point2D, CubicSegment）
- 契约：`note/src/main/ets/core/model/StrokeTypes.ets`（InputPoint, StrokePathPoint）

## 实现要求

### 创建文件

1. `note/src/main/ets/core/algorithm/ForceSmoother.ets`
2. `note/src/main/ets/core/algorithm/CubicFitter.ets`

### ForceSmoother.ets

```typescript
import { InputPoint } from '../model/StrokeTypes';

export interface ForceSmootherConfig {
  enabled: boolean;            // 默认 true
  smoothingWindowMs: number;   // 默认 8
  maxForceChange: number;      // 默认 0.15
}

export class ForceSmoother {
  private config: ForceSmootherConfig;
  private lastForce: number;   // 上一个平滑后的 force 值

  constructor(config?: Partial<ForceSmootherConfig>)

  // 对一批输入点做 force 平滑，返回新数组（不修改原数组）
  smooth(points: InputPoint[]): InputPoint[] {
    // 对每个点:
    // 1. 如果 pressure == -1（无压感），跳过
    // 2. delta = point.pressure - lastForce
    // 3. 如果 |delta| > maxForceChange，clamp 到 lastForce ± maxForceChange
    // 4. 更新 lastForce
    // 5. 返回新 InputPoint（pressure 替换为平滑值）
  }

  reset(): void { this.lastForce = -1; }
}
```

### CubicFitter.ets

```typescript
import { Point2D, CubicSegment } from '../model/GeometryTypes';
import { StrokePathPoint } from '../model/StrokeTypes';

export interface FitterConfig {
  maxPointsPerSegment: number;  // 默认 200
  contextExpansion: number;     // 默认 5
  baseTolerance: number;        // 默认 0.5（会被动态容差覆盖）
}

export class CubicFitter {
  private config: FitterConfig;

  constructor(config?: Partial<FitterConfig>)

  // 主入口：将中心线点序列拟合为三次贝塞尔段数组
  fit(points: StrokePathPoint[], baseWidth: number, zoom: number): CubicSegment[] {
    // 1. 计算动态容差: tolerance = computeTolerance(baseWidth, zoom)
    // 2. 调用 fitRecursive(points, 0, points.length-1, tolerance)
    // 3. 返回 CubicSegment[]
  }

  // 动态容差（§17 公式）
  private computeTolerance(baseWidth: number, zoom: number): number {
    // tolerance = (0.5 / ((((Math.log(baseWidth * zoom) - 2.6) / 15.4) * 1.5) + 1.0)) / zoom
    // 注：dd4.d() 用 Math.log 近似（待逆向确认后可能调整）
  }

  // 最小二乘求控制点（sqh.g）
  private fitCubic(points: Point2D[], start: number, end: number): CubicSegment {
    // 1. p0 = points[start], p3 = points[end]
    // 2. 构造三次 Bernstein 基函数 B(t) = (1-t)³p0 + 3(1-t)²t·p1 + 3(1-t)t²·p2 + t³·p3
    // 3. 对内部点建立超定方程，解 2×2 正规方程求 p1, p2
    // 4. 如果矩阵病态（行列式≈0）或结果非有限 → 回退：p1 = p0 + (p3-p0)/3, p2 = p0 + 2(p3-p0)/3
  }

  // 最大误差检查（sqh.h）
  private maxError(points: Point2D[], start: number, end: number, curve: CubicSegment): number {
    // 对 [start, end] 内每个点，计算到曲线最近距离（采样 t=0..1 步长 0.02）
    // 返回最大欧氏距离
  }

  // 二分分段（sqh.f）
  private fitRecursive(points: Point2D[], start: number, end: number, tolerance: number, result: CubicSegment[]): void {
    // 1. 如果 end - start > maxPointsPerSegment，截断
    // 2. fitCubic → curve
    // 3. maxError ≤ tolerance → 接受，push curve
    // 4. 否则二分：mid = (start+end)/2，递归 [start,mid] 和 [mid,end]
  }
}
```

### 鸿蒙特有约束

- **禁止** import 任何 `@ohos.*` / `@kit.*`（纯数学模块）。
- 所有方法参数和返回值显式标注类型。
- 不使用 `any`。
- 拟合输出为 `CubicSegment[]`，每段包含 p0/p1/p2/p3 四个 Point2D。
- `fit()` 不修改输入数组。
- 容差公式中 `dd4.d()` 暂用 `Math.log`（自然对数），后续可能根据逆向调整。

## 验收标准

- [ ] 两个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] ForceSmoother.smooth() 限制相邻 pressure 变化 ≤ 0.15
- [ ] CubicFitter.fit() 对直线输入返回近似直线的贝塞尔段
- [ ] CubicFitter.fit() 对 S 曲线输入返回多段
- [ ] 无平台 import
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-009-完成.md`
