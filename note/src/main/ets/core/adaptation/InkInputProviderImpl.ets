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
      points.push({
        x: raw.x,
        y: raw.y,
        elapsedTimeMillis: this.strokeStartTime >= 0 ? raw.timestamp - this.strokeStartTime : 0,
        toolType: raw.toolType === 0 ? InputToolType.STYLUS : InputToolType.TOUCH,
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
