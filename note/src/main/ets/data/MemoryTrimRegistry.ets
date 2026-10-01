import { hilog } from '@kit.PerformanceAnalysisKit';

// 原版内存压力缓存裁剪管线（Phase 1435）：
//   f1a.java  = 级别枚举 {BACKGROUNDED, CRITICAL}
//   h1a.java  = MemoryTrimmable 接口（a(f1a) 单回调）
//   g1a.java  = 注册表：a(h1a) 登记 / b(f1a) 逐回调分发——单个 trimmable
//               抛错不中断其余（收集后日志记录首异常），与本文件同语义。
//   NbApplication.onTrimMemory(i)：i>=40 → b(CRITICAL)；i>=20 →
//   b(BACKGROUNDED)；onLowMemory → b(CRITICAL)。Android i<20
//   （RUNNING_* 前台压力档）不触发裁剪 —— 故 Harmony
//   MEMORY_LEVEL_MODERATE（前台中等压力）同理不裁剪。
//   ehc.java 三个已登记 trimmable（全清语义，与级别无关）：
//     ehc(0) → hhc.b.clear()        资源解码位图缓存
//     ehc(1) → dpc.e.i(-1)          图片位图 LRU（容量降到 -1 = 全逐出）
//     ehc(2) → ctc.q                铅笔 splat 渲染池（SharedMemory + 池）
//   Harmony 对应缓存：LibraryPage.thumbMap（封面 PixelMap）、
//   NoteCanvasView.imageAssets（页内图元素 PixelMap）+
//   shapeRenderer.pencilCache（形状铅笔 splat LRU）。
export enum MemoryTrimLevel {
  BACKGROUNDED = 0,
  CRITICAL = 1,
}

export type MemoryTrimCallback = (level: MemoryTrimLevel) => void;

interface MemoryTrimmableEntry {
  name: string;
  callback: MemoryTrimCallback;
}

const trimmables: Map<number, MemoryTrimmableEntry> =
  new Map<number, MemoryTrimmableEntry>();
let nextToken: number = 1;

export function registerMemoryTrimmable(name: string,
  callback: MemoryTrimCallback): number {
  const token: number = nextToken;
  nextToken++;
  const entry: MemoryTrimmableEntry = { name: name, callback: callback };
  trimmables.set(token, entry);
  return token;
}

export function unregisterMemoryTrimmable(token: number): void {
  trimmables.delete(token);
}

// g1a.b 同语义：逐 trimmable 分发，单点失败不中断，汇总日志。
export function trimMemoryCaches(level: MemoryTrimLevel): void {
  hilog.info(0x0001, 'MemoryTrimRegistry',
    'Memory trim (%{public}s): releasing %{public}d caches',
    level === MemoryTrimLevel.CRITICAL ? 'CRITICAL' : 'BACKGROUNDED',
    trimmables.size);
  trimmables.forEach((entry: MemoryTrimmableEntry): void => {
    try {
      entry.callback(level);
    } catch (e) {
      hilog.error(0x0001, 'MemoryTrimRegistry',
        'MemoryTrimmable %{public}s failed: %{public}s',
        entry.name, JSON.stringify(e));
    }
  });
}
