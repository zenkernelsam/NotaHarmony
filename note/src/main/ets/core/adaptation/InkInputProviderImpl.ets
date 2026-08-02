// T-008 输入采集实现（任务卡 T-008，InkInputProvider 接口实现）
// 本文件不 import 平台 API：接收的是已转换的 RawPointerEvent
import { InkInputProvider, RawPointerEvent } from './InkInputProvider';
import { InputBatch, InputBatchKind, InputPoint, InputToolType } from '../model/StrokeTypes';

export class InkInputProviderImpl implements InkInputProvider {
  private pressureSupported: boolean;
  private tiltSupported: boolean;
  private orientationSupported: boolean;
  // 笔画起始时间戳（由调用方在 beginStroke 时设置，用于计算 elapsedTimeMillis）
  private strokeStartTime: number = -1;

  constructor(pressureSupported: boolean, tiltSupported: boolean, orientationSupported: boolean) {
    this.pressureSupported = pressureSupported;
    this.tiltSupported = tiltSupported;
    this.orientationSupported = orientationSupported;
  }

  // 实现类扩展方法：标记新笔画开始（调用方在 touchDown 时调用）
  beginStroke(startTime: number): void {
    this.strokeStartTime = startTime;
  }

  processEvent(rawEvents: RawPointerEvent[], isPredicted: boolean): InputBatch {
    if (rawEvents.length === 0) {
      return { kind: InputBatchKind.REAL, points: [] };
    }
    const kind: InputBatchKind = isPredicted ? InputBatchKind.PREDICTED :
      (rawEvents[0].isHistorical ? InputBatchKind.HISTORICAL : InputBatchKind.REAL);
    const points: InputPoint[] = [];
    for (const raw of rawEvents) {
      // §5 已审计结论：predicted MotionEvent 时间戳为 0 时忽略
      if (isPredicted && raw.timestamp <= 0) {
        continue;
      }
      points.push({
        x: raw.x,
        y: raw.y,
        elapsedTimeMillis: this.strokeStartTime >= 0 ? raw.timestamp - this.strokeStartTime : 0,
        // §5 映射：stylus/eraser→STYLUS(0)、mouse→MOUSE(1)、其他→TOUCH(2)
        // （页面层将 stylus/eraser 归类为 0，mouse 归类为 1）
        toolType: this.mapToolType(raw.toolType),
        pressure: this.pressureSupported ? this.clamp(raw.pressure, 0, 1) : -1,
        tiltRadians: this.tiltSupported ? this.clamp(raw.tiltRadians, 0, Math.PI / 2) : -1,
        orientationRadians: this.orientationSupported ? this.normalizeOrientation(raw.orientationRadians) : -1,
      });
    }
    return { kind: kind, points: points };
  }

  hasPressureSupport(): boolean {
    return this.pressureSupported;
  }

  hasTiltSupport(): boolean {
    return this.tiltSupported;
  }

  hasOrientationSupport(): boolean {
    return this.orientationSupported;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
  }

  // §5 工具映射：stylus/eraser→STYLUS、mouse→MOUSE、其他→TOUCH
  private mapToolType(rawType: number): InputToolType {
    if (rawType === 0) {
      return InputToolType.STYLUS;
    }
    if (rawType === 1) {
      return InputToolType.MOUSE;
    }
    return InputToolType.TOUCH;
  }

  // 归一化到 [0, 2π)
  private normalizeOrientation(value: number): number {
    const twoPi = Math.PI * 2;
    let result = value % twoPi;
    if (result < 0) {
      result += twoPi;
    }
    return result;
  }
}
