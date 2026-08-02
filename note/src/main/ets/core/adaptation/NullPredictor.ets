// T-008 预测点空实现（任务卡 T-008，Predictor 接口实现）
// 不产生预测点：低延迟预测为可选项，模拟器 MVP 阶段使用
import { Predictor } from './Predictor';
import { InputPoint } from '../model/StrokeTypes';

export class NullPredictor implements Predictor {
  predict(_history: InputPoint[]): InputPoint[] {
    return [];
  }

  reset(): void {
    // 无状态
  }
}
