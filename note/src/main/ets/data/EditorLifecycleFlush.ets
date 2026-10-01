import { hilog } from '@kit.PerformanceAnalysisKit';

// 原版生命周期审计（Phase 1432）：MainActivity.onPause 仅注销加速度
// 传感器、onDestroy 仅做 Play 评审/S Pen 清理——无显式落盘；原版笔
// 记状态经 zhi.emit→tee.a0 按变更写穿透库，文本编辑态本身即文档模
// 型字段，后台/进程回收不会丢稿。Harmony 侧文本草稿
// （editingDraftText）、标题草稿与 LatestWriteQueue 挂起写属进程内
// 缓冲，onBackground 不冲刷则系统回收即丢稿——故登记前台页面回调，
// onBackground 触发与 performLeaveEditor 前半等价的尽力冲刷（不导
// 航、不停录音：原版 RecordingForegroundService 使录音后台续录）。
export type BackgroundFlushCallback = () => Promise<void>;

const callbacks: Map<number, BackgroundFlushCallback> =
  new Map<number, BackgroundFlushCallback>();
let nextToken: number = 1;

export function registerBackgroundFlush(callback: BackgroundFlushCallback): number {
  const token: number = nextToken;
  nextToken++;
  callbacks.set(token, callback);
  return token;
}

export function unregisterBackgroundFlush(token: number): void {
  callbacks.delete(token);
}

export function flushEditorsForBackground(): void {
  callbacks.forEach((callback: BackgroundFlushCallback): void => {
    callback().catch((e: Error): void => {
      hilog.error(0x0001, 'EditorLifecycleFlush',
        'background flush failed: %{public}s', JSON.stringify(e));
    });
  });
}
