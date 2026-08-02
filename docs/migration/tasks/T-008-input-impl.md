# T-008 输入采集实现

## 目标

实现 InkInputProvider 接口的具体类（TouchEvent → InputBatch），以及 Predictor 的两个实现（PenKit 预测 + 空实现）。

## 参考

- 知识库：REVERSE_ANALYSIS.md §5（hda.v() 字段映射：pressure clamp [0,1]、tilt clamp [0,π/2]、orientation 归一化 [0,2π)、无能力时 -1）、§36（Pen Kit PointPredictor API）
- 契约：`note/src/main/ets/core/adaptation/InkInputProvider.ets`（接口定义，不得修改）
- 契约：`note/src/main/ets/core/adaptation/Predictor.ets`（接口定义，不得修改）
- 契约：`note/src/main/ets/core/model/StrokeTypes.ets`（InputPoint/InputBatch/InputBatchKind）

## 实现要求

### 创建文件

1. `note/src/main/ets/core/adaptation/InkInputProviderImpl.ets`
2. `note/src/main/ets/core/adaptation/PenKitPredictor.ets`
3. `note/src/main/ets/core/adaptation/NullPredictor.ets`

### InkInputProviderImpl.ets

```typescript
import { InkInputProvider, RawPointerEvent } from './InkInputProvider';
import { InputBatch, InputBatchKind, InputPoint, InputToolType } from '../model/StrokeTypes';

export class InkInputProviderImpl implements InkInputProvider {
  // 设备能力标记（构造时传入或首次事件检测）
  private pressureSupported: boolean;
  private tiltSupported: boolean;
  private orientationSupported: boolean;

  constructor(pressureSupported: boolean, tiltSupported: boolean, orientationSupported: boolean)

  processEvent(rawEvents: RawPointerEvent[], isPredicted: boolean): InputBatch {
    // 1. kind = isPredicted ? PREDICTED : (rawEvents[0].isHistorical ? HISTORICAL : REAL)
    // 2. 对每个 rawEvent 转为 InputPoint:
    //    - pressure: 有支持时 clamp [0,1]，否则 -1
    //    - tiltRadians: 有支持时 clamp [0, π/2]，否则 -1
    //    - orientationRadians: 有支持时归一化 [0, 2π)，否则 -1
    //    - toolType: 映射（0→STYLUS, 其他→TOUCH）
    //    - elapsedTimeMillis: rawEvent.timestamp - strokeStartTime（由调用方管理）
    // 3. 返回 InputBatch
  }

  hasPressureSupport(): boolean
  hasTiltSupport(): boolean
  hasOrientationSupport(): boolean
}
```

### PenKitPredictor.ets

```typescript
import { Predictor } from './Predictor';
import { InputPoint } from '../model/StrokeTypes';
// 注意：此文件可以 import @kit.Penkit（它是适配层实现，不是业务层）

export class PenKitPredictor implements Predictor {
  // 尝试使用 PointPredictor；如果不可用则退化为线性外推
  predict(history: InputPoint[]): InputPoint[] {
    // 如果 history.length < 2 返回 []
    // 线性外推：取最后两点，按速度方向外推 1-2 个点
    // 未来接入 PointPredictor.getPredictionPoint()
  }
  reset(): void {}
}
```

### NullPredictor.ets

```typescript
import { Predictor } from './Predictor';
import { InputPoint } from '../model/StrokeTypes';

export class NullPredictor implements Predictor {
  predict(history: InputPoint[]): InputPoint[] { return []; }
  reset(): void {}
}
```

### 鸿蒙特有约束

- InkInputProviderImpl **不 import 平台 API**（它接收的是已转换的 RawPointerEvent）。
- PenKitPredictor **可以** import `@kit.Penkit`（适配层实现允许），但当前版本先用线性外推，不实际调用 PointPredictor（模拟器可能不支持）。
- TouchEvent → RawPointerEvent 的转换在 T-015 的页面层做，不在本文件。
- pressure 归一化：HarmonyOS TouchPoint.pressure 范围 [0, 65535)，需除以 65535 归一化到 [0,1]。但这个转换在页面层做；本层假设 RawPointerEvent.pressure 已经是原始值，由 processEvent 内部 clamp。

## 验收标准

- [ ] 三个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] InkInputProviderImpl implements InkInputProvider（编译级验证）
- [ ] PenKitPredictor / NullPredictor implements Predictor
- [ ] processEvent 对无能力设备返回 pressure=-1, tilt=-1, orientation=-1
- [ ] 不修改 Phase 1 契约文件

## 完成报告

`docs/migration/reports/T-008-完成.md`
