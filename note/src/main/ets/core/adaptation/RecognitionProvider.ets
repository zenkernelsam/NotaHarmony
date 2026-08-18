// T-006 可插拔识别模组接口（契约 phase-1-data-model.md §3.8，照搬，禁止修改签名）
// 适配层接口：主流程不依赖其实现，待模组成熟后再接入
// 接口定义不 import 任何 @ohos.* / @kit.* 平台模块
import { Point2D } from '../model/GeometryTypes';
import { NoteElement } from '../model/ElementTypes';

// 识别结果
export interface RecognitionResult {
  confidence: number;       // [0,1]
  elements: NoteElement[];  // 识别产出的元素
}

// 可插拔识别接口（主流程不依赖实现）
export interface RecognitionProvider {
  // 是否可用
  isAvailable(): boolean;
  // 形状识别（笔画完成后调用）
  recognizeShape(points: Point2D[]): RecognitionResult | null;
  // 旧 phase-1 同步扁平点占位签名；它缺少原版要求的语言、笔迹分段与 force。
  // 生产手写 OCR 不得复用 ShapeDetector 的可用性，必须走
  // OriginalHandwritingRecognition 的独立异步 provider 边界。
  recognizeText(points: Point2D[]): string | null;
}
