// T-006 预测点适配接口（契约 phase-1-data-model.md §3.8，照搬，禁止修改签名）
// 适配层接口：低延迟预测点抽象，可为空实现
// 接口定义不 import 任何 @ohos.* / @kit.* 平台模块
import { InputPoint } from '../model/StrokeTypes';

export interface Predictor {
  // 基于历史点生成预测点（可为空实现）
  predict(history: InputPoint[]): InputPoint[];
  // 重置状态（新笔画开始时调用）
  reset(): void;
}
