# T-014 笔画会话与橡皮擦

## 目标

实现进行中笔画的状态机（StrokeSession：管理从 touchDown 到 touchUp 的完整生命周期）和橡皮擦引擎（PARTIAL 挖洞 + WHOLE 整条删除）。

## 参考

- 知识库：REVERSE_ANALYSIS.md §6（s78 渲染态笔画：finishInput/cancel 标记、三缓冲路径）、§5b（PARTIAL clipOutPath + WHOLE 整条删除）、§17（平滑链：输入→ForceSmoother→CubicFitter→轮廓）
- 契约：Phase 1 全部 model 类型
- 依赖：T-009（ForceSmoother + CubicFitter）、T-010（WidthOutlineBuilder）、T-011（PencilSplatGenerator）、T-013（StrokeLayerManager）

## 实现要求

### 创建文件

1. `note/src/main/ets/rendering/StrokeSession.ets`
2. `note/src/main/ets/rendering/EraserEngine.ets`

### StrokeSession.ets

```typescript
import { InputBatch, InputPoint, StrokeElementData, StrokePathPoint, PencilSplatPoint, RenderSpec, InkStyle } from '../core/model/StrokeTypes';
import { CubicSegment, Point2D, Rect2D } from '../core/model/GeometryTypes';
import { ForceSmoother } from '../core/algorithm/ForceSmoother';
import { CubicFitter } from '../core/algorithm/CubicFitter';
import { WidthOutlineBuilder, OutlineResult } from '../core/algorithm/WidthOutlineBuilder';
import { PencilSplatGenerator } from '../core/algorithm/PencilSplatGenerator';

export class StrokeSession {
  private smoother: ForceSmoother;
  private fitter: CubicFitter;
  private outlineBuilder: WidthOutlineBuilder;
  private splatGenerator: PencilSplatGenerator;

  // 当前笔画状态
  private rawPoints: InputPoint[] = [];
  private pathPoints: StrokePathPoint[] = [];
  private cubicSegments: CubicSegment[] = [];
  private splatPoints: PencilSplatPoint[] = [];
  private outline: OutlineResult | null = null;
  private renderSpec: RenderSpec;
  private isActive: boolean = false;
  private strokeId: string = '';
  private startTime: number = 0;

  constructor(renderSpec: RenderSpec)

  // 开始新笔画
  beginStroke(spec: RenderSpec, timestamp: number): void {
    // 重置所有状态，生成新 strokeId，记录 startTime
    // smoother.reset(), splatGenerator.reset(seed)
  }

  // 添加输入批次（每帧调用）
  addBatch(batch: InputBatch): void {
    // 1. 将 batch.points 加入 rawPoints
    // 2. 转为 StrokePathPoint（position + widthFactor 从 pressure 推导）
    // 3. smoother.smooth() → 平滑
    // 4. fitter.fit() → cubicSegments
    // 5. 如果是铅笔 → splatGenerator.generate() → splatPoints
    // 6. 如果是 VARIABLE_WIDTH → outlineBuilder.build() → outline
    // 7. 计算 bounds
  }

  // 完成笔画 → 返回完整 StrokeElementData
  finishStroke(): StrokeElementData {
    // 组装 StrokeElementData（id/pathPoints/cubicSegments/splatPoints/renderSpec/transform/bounds/maskPath/isFinished=true）
  }

  // 取消笔画
  cancelStroke(): void

  // 获取当前笔画的实时渲染数据（供渲染器每帧使用）
  getCurrentStroke(): StrokeElementData | null

  // widthFactor 推导：pressure → widthFactor
  private pressureToWidthFactor(pressure: number): number {
    // pressure == -1 → 1.0（无压感）
    // 否则 → 0.3 + 0.7 * pressure（线性映射，最小 30% 宽度）
  }

  isActive(): boolean
}
```

### EraserEngine.ets

```typescript
import { StrokeElementData } from '../core/model/StrokeTypes';
import { Point2D, Rect2D } from '../core/model/GeometryTypes';

export enum EraserMode {
  PARTIAL = 0,  // 像素擦除（挖洞）
  WHOLE = 1,    // 整条删除
}

export interface EraseResult {
  mode: EraserMode;
  // PARTIAL: 受影响的笔画（maskPath 已更新）
  affectedStrokes: StrokeElementData[];
  // WHOLE: 应删除的笔画 ID
  deletedStrokeIds: string[];
}

export class EraserEngine {
  private mode: EraserMode;
  private eraserWidth: number;  // 擦除宽度（默认 20）

  constructor(mode: EraserMode, eraserWidth?: number)

  // 执行擦除（传入擦除路径点 + 当前所有笔画）
  erase(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    if (this.mode === EraserMode.WHOLE) {
      return this.eraseWhole(eraserPath, strokes);
    } else {
      return this.erasePartial(eraserPath, strokes);
    }
  }

  // WHOLE: 擦除路径与笔画 bounds 相交 → 整条删除
  private eraseWhole(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    // 1. 计算擦除路径的 bounds（膨胀 eraserWidth/2）
    // 2. 对每条笔画：如果 bounds 相交 → 标记删除
    // 3. 可选：精确检测擦除路径与笔画路径的距离 < eraserWidth/2
  }

  // PARTIAL: 将擦除路径写入受影响笔画的 maskPath
  private erasePartial(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    // 1. 找到与擦除路径相交的笔画
    // 2. 将擦除路径点追加到该笔画的 maskPath
    // 3. 渲染器后续用 destination-out 挖洞
  }

  // 碰撞检测：点与笔画 bounds 是否相交
  private intersectsBounds(path: Point2D[], bounds: Rect2D, radius: number): boolean

  setMode(mode: EraserMode): void
  setWidth(width: number): void
}
```

### 鸿蒙特有约束

- StrokeSession 中**禁止** import 平台 API（它只调用算法模块和模型类型）。
- EraserEngine 同样**禁止**平台 API（纯几何碰撞检测）。
- strokeId 生成：`Date.now().toString(36) + Math.random().toString(36).slice(2, 8)`。
- widthFactor 映射公式可由构造器配置（默认 `0.3 + 0.7 * pressure`）。
- PARTIAL 擦除不删除笔画，只追加 maskPath；WHOLE 擦除返回待删除 ID 列表。
- EraserEngine 的碰撞检测 MVP 用 bounds 相交即可，不需要精确路径相交。

## 验收标准

- [ ] 两个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] StrokeSession.beginStroke → addBatch → finishStroke 生命周期完整
- [ ] finishStroke 返回 isFinished=true 的 StrokeElementData
- [ ] EraserEngine WHOLE 模式返回 deletedStrokeIds
- [ ] EraserEngine PARTIAL 模式返回 affectedStrokes（maskPath 非空）
- [ ] 无平台 import
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-014-完成.md`
