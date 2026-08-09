import { PointPredictor } from '@kit.Penkit';
import { PredictionCoordinates, Predictor } from './Predictor';

// HarmonyOS 5.0/API 12 起的系统手写预测器。与原版 AndroidX Ink 一样，预测只来自平台输入层。
export class PenKitPredictor implements Predictor<TouchEvent> {
  private pointPredictor: PointPredictor | null = null;

  predict(event: TouchEvent): PredictionCoordinates | null {
    try {
      if (this.pointPredictor === null) {
        this.pointPredictor = new PointPredictor();
      }
      const point: TouchPoint = this.pointPredictor.getPredictionPoint(event);
      if (typeof point.x !== 'number' || typeof point.y !== 'number' ||
        !Number.isFinite(point.x) || !Number.isFinite(point.y)) {
        return null;
      }
      return { x: point.x, y: point.y };
    } catch (_error) {
      // 不支持 SystemCapability.Stylus.Handwrite 的设备必须无损降级为无预测。
      return null;
    }
  }

  reset(): void {
    // PointPredictor 的公开 API 没有可重置状态；它从传入 TouchEvent 的历史样本计算。
  }
}
