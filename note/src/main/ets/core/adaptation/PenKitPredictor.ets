// T-008 预测点实现（任务卡 T-008，Predictor 接口实现）
// 当前版本使用线性外推（模拟器可能不支持 PointPredictor）；
// 未来可接入 @kit.Penkit 的 PointPredictor.getPredictionPoint()（适配层实现允许平台 import）
import { Predictor } from './Predictor';
import { InputPoint } from '../model/StrokeTypes';

export class PenKitPredictor implements Predictor {
  // 基于历史点生成预测点：取最后两点速度方向线性外推 2 个点
  predict(history: InputPoint[]): InputPoint[] {
    if (history.length < 2) {
      return [];
    }
    const last = history[history.length - 1];
    const prev = history[history.length - 2];
    const dx = last.x - prev.x;
    const dy = last.y - prev.y;
    const dt = Math.max(last.elapsedTimeMillis - prev.elapsedTimeMillis, 1);
    const results: InputPoint[] = [];
    for (let i = 1; i <= 2; i++) {
      results.push({
        x: last.x + dx * i,
        y: last.y + dy * i,
        elapsedTimeMillis: last.elapsedTimeMillis + dt * i,
        toolType: last.toolType,
        pressure: last.pressure,
        tiltRadians: last.tiltRadians,
        orientationRadians: last.orientationRadians,
      });
    }
    return results;
  }

  reset(): void {
    // 线性外推无内部状态
  }
}
