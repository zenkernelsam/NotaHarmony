// T-009 力平滑器（任务卡 T-009，REVERSE_ANALYSIS §17：dr4 ForceSmootherConfig）
// 纯数学模块：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { InputPoint } from '../model/StrokeTypes';

export interface ForceSmootherConfig {
  enabled: boolean;            // 默认 true（dr4 构造器）
  smoothingWindowMs: number;   // 默认 8（原版 ws4 smoothingWindow）
  maxForceChange: number;      // 默认 0.15（dr4 参数：单点最大 force 变化）
}

export class ForceSmoother {
  private config: ForceSmootherConfig;
  private lastForce: number = -1;  // 上一个平滑后的 force 值（-1 = 无历史）
  private lastTimeMs: number = -1;

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

  // updateState=false 对应原版 ue4.a(..., predicted=true)：预测点不平滑，也不污染真实点状态。
  smooth(points: InputPoint[], updateState: boolean = true): InputPoint[] {
    const result: InputPoint[] = [];
    for (const p of points) {
      if (!updateState || !this.config.enabled) {
        result.push(p);
        continue;
      }

      // 有意偏离原版：HarmonyOS 输入适配层用 -1 表示设备没有压感能力。
      // 哨兵不能参与数值平滑，也不能覆盖最后一个有效压力状态。
      if (p.pressure < 0) {
        result.push(p);
        continue;
      }

      let force: number = p.pressure;
      if (this.lastForce >= 0 && this.lastTimeMs >= 0) {
        const dt: number = Math.max(p.elapsedTimeMillis - this.lastTimeMs, 0);
        const t: number = Math.min(Math.max(dt / this.config.smoothingWindowMs, 0), 1);
        const blended: number = this.lastForce * (1 - t) + p.pressure * t;
        const delta: number = Math.min(
          Math.max(blended - this.lastForce, -this.config.maxForceChange),
          this.config.maxForceChange,
        );
        force = this.lastForce + delta;
      }
      this.lastForce = force;
      this.lastTimeMs = p.elapsedTimeMillis;
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
    this.lastTimeMs = -1;
  }
}
