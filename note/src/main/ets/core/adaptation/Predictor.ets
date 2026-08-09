// 低延迟预测适配接口。事件类型由平台实现注入，核心契约不依赖任何 @ohos.* / @kit.* 模块。
export interface PredictionCoordinates {
  x: number;
  y: number;
}

export interface Predictor<TEvent> {
  // 每个真实输入帧最多产生一个临时尾点；无有效系统预测时返回 null。
  predict(event: TEvent): PredictionCoordinates | null;
  // 重置状态（新笔画开始时调用）
  reset(): void;
}
