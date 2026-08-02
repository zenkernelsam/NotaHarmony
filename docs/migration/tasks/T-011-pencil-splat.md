# T-011 PencilSplat 生成器

## 目标

实现 §18 完整公式的 PencilSplat 点生成算法：确定性 LCG 随机 + 椭圆盘散布 + 压感⁵缓动 + 倾斜响应。

## 参考

- 知识库：REVERSE_ANALYSIS.md §18（完整公式：xaa.b() 每个 splat 的 position/rotation/scale/opacity 计算，LCG 乘子 1118393071/1946926193，压感 5 次方，倾斜归一化 -0.94248，椭圆收缩 0.9，角度细分 π/125）
- 契约：`note/src/main/ets/core/model/StrokeTypes.ets`（PencilSplatPoint, StrokePathPoint）
- 契约：`note/src/main/ets/core/model/GeometryTypes.ets`（Point2D, CubicSegment）

## 实现要求

### 创建文件

`note/src/main/ets/core/algorithm/PencilSplatGenerator.ets`

### 接口设计

```typescript
import { PencilSplatPoint, StrokePathPoint } from '../model/StrokeTypes';
import { CubicSegment } from '../model/GeometryTypes';

export interface SplatGeneratorConfig {
  spacing: number;          // splat 间距（默认 2.0）
  pressurePower: number;    // 压感幂次（默认 5）
  tiltNormalize: number;    // 倾斜归一化除数（默认 -0.94248）
  ellipseShrink: number;    // 椭圆 x 收缩（默认 0.9）
  angleStep: number;        // 角度细分步长（默认 π/125）
  maxSubdivisions: number;  // 最大细分（默认 26）
  lcgMultiplier: number;    // LCG 乘子（默认 1118393071）
  lcgModulus: number;       // LCG 模数（默认 1946926193）
}

export class PencilSplatGenerator {
  private config: SplatGeneratorConfig;
  private seed: number;

  constructor(config?: Partial<SplatGeneratorConfig>)

  // 主入口：沿曲线生成 splat 点
  generate(segments: CubicSegment[], pathPoints: StrokePathPoint[]): PencilSplatPoint[] {
    // 1. 沿曲线等距行走（间距 = config.spacing）
    // 2. 每个位置调用 generateAtPosition()
    // 3. 收集所有 splat 点
  }

  // 单位置 splat 生成（对应 xaa.b()）
  private generateAtPosition(
    pos: Point2D, tangent: Point2D,
    pressure: number, tilt: number, orientation: number, width: number
  ): PencilSplatPoint[] {
    // 完整公式见下方
  }

  // LCG 伪随机（确定性！）
  private nextRandom(): number {
    this.seed = (this.seed * this.config.lcgMultiplier) % this.config.lcgModulus;
    return this.seed / this.config.lcgModulus;
  }

  // 沿贝塞尔曲线等距前进（二分查找弧长）
  private advanceByDistance(segments: CubicSegment[], distance: number): { pos: Point2D; tangent: Point2D } {
    // 二分查找 t 使弧长 ≈ distance
  }

  reset(seed: number): void { this.seed = seed; }
}
```

### 完整公式（工人必须精确实现）

```
// === 尺寸系数（xaa.d()）===
power5(x) = x * x * x * x * x
clampedPressure = min(pressure, 2.0) / 2.0
sizePressure = 1 - power5(1 - clampedPressure)
tiltNorm = min((tilt - π/2) / config.tiltNormalize, 1.0)   // tiltNormalize = -0.94248
sizeTilt = 1 - power5(tiltNorm)
sizeFactor = sizePressure * sizeTilt + (1 - sizeTilt) * 1.0

// === 散布盘参数 ===
scaleBase = min(width, 2.0) / 2.0 * 0.97 + 0.03
angleDiff = max(π/5 - orientation, 0)
splatCount = floor(angleDiff / config.angleStep) + 1   // 最多 26
ellipseR = 1.2 * (spacing / 2.0) * 0.5 * floor(angleDiff / config.angleStep)
ellipseS = (angleDiff / (π/2)) * (-0.48) + 0.5
baseScale = ellipseS * spacing * sizeFactor

// === 每 splat 随机散布 ===
angleNorm = min(max(angleDiff / 0.45332, 0), 1)
edgeFactor = (1 - angleNorm) + 0.1 * angleNorm

for i in 0..splatCount-1:
  u1 = nextRandom()
  θ = nextRandom() * 2π
  r = sqrt(u1)
  x = config.ellipseShrink * cos(θ) * r     // 0.9 收缩
  len = (angleNorm + sin(θ)) * 1.0
  // 位置 = 曲线点 + 切线/法线偏移
  splatX = pos.x + (len * tangent.y + x * (-tangent.x)) * ellipseR
  splatY = pos.y + (len * tangent.x + x * tangent.y) * ellipseR  // 注意：原版切线分量
  rotation = nextRandom() * 2π
  opacity = (1 - sqrt(u1)) * edgeFactor * scaleBase
  scale = baseScale

  output: PencilSplatPoint(splatX, splatY, rotation, scale, opacity)
```

### 鸿蒙特有约束

- **禁止** import 任何 `@ohos.*` / `@kit.*`（纯数学模块）。
- LCG 必须是确定性的：相同 seed + 相同输入 = 相同输出（可复现）。
- 默认 seed = 42（可由调用方重置）。
- pressure = -1 时视为 0.5（无压感设备的默认值）。
- tilt = -1 时视为 π/4（45° 默认倾斜）。
- orientation = -1 时视为 0。
- spacing 如果 ≤ 0，直接返回空数组。

## 验收标准

- [ ] 文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] 相同输入两次调用产生相同输出（确定性）
- [ ] pressure=1 比 pressure=0.2 产生更大的 scale
- [ ] splatCount 随 orientation 变化（orientation=0 时最多）
- [ ] opacity 在 [0,1] 范围内
- [ ] 无平台 import
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-011-完成.md`
