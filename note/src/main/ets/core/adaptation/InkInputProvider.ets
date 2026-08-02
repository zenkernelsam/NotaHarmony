// T-006 输入采集适配接口（契约 phase-1-data-model.md §3.8，照搬，禁止修改签名）
// 适配层接口：业务层不直接 import @ohos TouchEvent，平台无关中间表示
// 接口定义不 import 任何 @ohos.* / @kit.* 平台模块
import { InputBatch } from '../model/StrokeTypes';

// 触摸/笔事件抽象（业务层不直接 import @ohos TouchEvent）
export interface RawPointerEvent {
  x: number;
  y: number;
  pressure: number;
  tiltRadians: number;
  orientationRadians: number;
  toolType: number;
  timestamp: number;
  isHistorical: boolean;
}

export interface InkInputProvider {
  // 将平台原始事件转为标准输入批次
  processEvent(rawEvents: RawPointerEvent[], isPredicted: boolean): InputBatch;
  // 获取设备能力
  hasPressureSupport(): boolean;
  hasTiltSupport(): boolean;
  hasOrientationSupport(): boolean;
}
