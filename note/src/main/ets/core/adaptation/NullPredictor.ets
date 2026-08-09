import { PredictionCoordinates, Predictor } from './Predictor';

export class NullPredictor<TEvent> implements Predictor<TEvent> {
  predict(_event: TEvent): PredictionCoordinates | null {
    return null;
  }

  reset(): void {
    // 无状态
  }
}
