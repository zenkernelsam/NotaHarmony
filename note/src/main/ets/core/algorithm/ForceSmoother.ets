// T-009 力平滑器（任务卡 T-009，REVERSE_ANALYSIS §17：dr4 ForceSmootherConfig）
// 纯数学模块：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { InputPoint } from '../model/StrokeTypes';

export interface ForceSmootherConfig {
  enabled: boolean;            // 默认 true（dr4 构造器）
  smoothingWindowMs: number;   // 默认 8（dr4 参数，窗口预留）
  maxForceChange: number;      // 默认 0.15（dr4 参数：单点最大 force 变化）
}

export class ForceSmoother {
  private config: ForceSmootherConfig;
  private lastForce: number = -1;  // 上一个平滑后的 force 值（-1 = 无历史）

  constructor(config?: Partial<ForceSmootherConfig>) {
    const merged: ForceSmootherConfig = {
      enabled: true,
      smoothingWindowMs: 8,
      maxForceChange: 0.15,
    };
    if (config !== undefined) {
      if (config.enabled !== undefined) {
        merged.enabled = config.enabled;
      }
      if (config.smoothingWindowMs !== undefined) {
        merged.smoothingWindowMs = config.smoothingWindowMs;
      }
      if (config.maxForceChange !== undefined) {
        merged.maxForceChange = config.maxForceChange;
      }
    }
    this.config = merged;
  }

  // 对一批输入点做 force 平滑，返回新数组（不修改原数组）
  smooth(points: InputPoint[]): InputPoint[] {
    const result: InputPoint[] = [];
    for (const p of points) {
      if (!this.config.enabled || p.pressure < 0) {
        // 未启用或无压感：原样保留（不更新 lastForce）
        result.push(p);
        continue;
      }
      let force: number = p.pressure;
      if (this.lastForce >= 0) {
        const delta: number = p.pressure - this.lastForce;
        if (delta > this.config.maxForceChange) {
          force = this.lastForce + this.config.maxForceChange;
        } else if (delta < -this.config.maxForceChange) {
          force = this.lastForce - this.config.maxForceChange;
        }
      }
      this.lastForce = force;
      result.push({
        x: p.x,
        y: p.y,
        elapsedTimeMillis: p.elapsedTimeMillis,
        toolType: p.toolType,
        pressure: force,
        tiltRadians: p.tiltRadians,
        orientationRadians: p.orientationRadians,
      });
    }
    return result;
  }

  reset(): void {
    this.lastForce = -1;
  }
}
