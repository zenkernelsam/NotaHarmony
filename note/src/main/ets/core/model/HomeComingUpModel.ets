// 原版 Library Home "Coming Up"（nan/kan/m70/lb2/jt1/cbl）的纯数据模型。
//
// 证据链（decompiled_1.4.2）：
// - jt1:959  CalendarContract.Instances 查询窗口 = [今日 0 点, 今日+10 天 0 点)
//            `visible = 1` + `begin ASC`；cbl.a projection；权限缺失 →
//            bh1(events, isReadable=false)。
// - cbl:~195  游标→ag1 映射：selfAttendeeStatus==2（ATTENDEE_DECLINED）跳过；
//            allDay=1 → cbl.e 把 UTC 午夜换算为本地午夜；标题列空 → 渲染层
//            "Untitled event" 回退（aa case2）；rrule/rdate/originalInstanceTime
//            仅用于标识循环实例。
// - m70 case7 事件流 → kb2{days, isReadable, now, zone}：
//   1) 过滤 end > now；
//   2) 分组键 = max(event.start, 今日 0 点) 的本地日期（跨日仍在进行的事件
//      归入"今天"）；
//   3) 组内按开始时间升序（`begin ASC` 同序）；
//   4) 发出 [今日组(可为空)] + 之后日期组（升序）。
// - lb2.a     行状态：isAllDay → UPCOMING；now<start 且差值≤10min →
//            STARTING_SOON；now≥start → HAPPENING_NOW。
// - nan.i     za2 窗口分页：每个窗口 ≤3 个日分组且事件总数 ≤10（单日超限
//            仍独占一个窗口）；‹/› 按钮（cd = earlier_days/later_days）在
//            边界禁用；选中态按窗口起始日记忆（rga）。
// - 差异登记：SYLLABUS（lhh 课表/考试后端）事件源不随本 Phase 移植（无后端）；
//   selfAttendeeStatus/visible 过滤在 Harmony calendarManager 内不可移植，
//   由系统 Provider 等价约束，详见 ADR。

/** lb2.a —— "Starting soon" 阈值 = 10 分钟。 */
export const COMING_UP_STARTING_SOON_MS: number = 10 * 60 * 1000;
/** jt1:959 —— Instances 查询窗口 = 今日起 10 天。 */
export const COMING_UP_RANGE_DAYS: number = 10;
/** nan.i za2 分窗：每窗最多 3 个日分组。 */
export const COMING_UP_WINDOW_DAY_LIMIT: number = 3;
/** nan.i za2 分窗：每窗最多 10 个事件（单日超限例外）。 */
export const COMING_UP_WINDOW_EVENT_LIMIT: number = 10;

/** zf1 —— 事件来源；SYLLABUS 保留枚举位但当前无本地产物（后端课表未移植）。 */
export enum ComingUpEventSource {
  DEVICE = 'device',
  SYLLABUS = 'syllabus',
}

/** wa2 —— 事件行状态（lb2.a 时序判定）。 */
export enum ComingUpEventState {
  UPCOMING = 'upcoming',
  STARTING_SOON = 'starting_soon',
  HAPPENING_NOW = 'happening_now',
}

/** ag1 中移植所需的字段子集。 */
export interface ComingUpEvent {
  /** ag1.a —— 稳定行键（设备事件 = event_id；查询缺省时回退合成）。 */
  id: string;
  /** ag1.c —— 标题列原始值；空串 → 渲染层 Untitled event。 */
  title: string;
  /** ag1.d —— 开始时刻（allDay 已按 cbl.e 换算为本地午夜）。 */
  startMs: number;
  /** ag1.e —— 结束时刻。 */
  endMs: number;
  /** ag1.h —— 全天事件。 */
  isAllDay: boolean;
  /** ag1.j —— 事件来源。 */
  source: ComingUpEventSource;
}

/** xa2 —— 一个本地日期的分组。 */
export interface ComingUpDayGroup {
  /** 本地 yyyy-mm-dd 键。 */
  dateKey: string;
  /** 当日 0 点的毫秒时间戳（本地时区）。 */
  dayStartMs: number;
  events: ComingUpEvent[];
}

/** za2 —— 一个展示窗口（≤3 日分组、≤10 事件）。 */
export interface ComingUpWindow {
  /** za2.a —— 窗口起始日（rga 选中态记忆键）。 */
  startDateKey: string;
  groups: ComingUpDayGroup[];
  /** za2.c —— 下一窗口起始日（无则 null）。 */
  nextDateKey: string | null;
}

/** kb2 —— 面板数据：日分组 + 可读性标记。 */
export interface ComingUpModel {
  days: ComingUpDayGroup[];
  /** bh1.b —— 日历可读（权限已授予且查询成功）。 */
  isReadable: boolean;
}

/** 本地时区 yyyy-mm-dd。 */
export function comingUpDateKey(ms: number): string {
  const d: Date = new Date(ms);
  const month: string = String(d.getMonth() + 1).padStart(2, '0');
  const day: string = String(d.getDate()).padStart(2, '0');
  return `${d.getFullYear()}-${month}-${day}`;
}

/** 本地当日 0 点时间戳。 */
export function comingUpDayStartMs(ms: number): number {
  const d: Date = new Date(ms);
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
}

/**
 * m70 case7 复现：过滤未结束 → 跨日进行中的事件 clamp 到今日 → 按本地
 * 日期分组 → [今日组] + 未来日组升序；组内按开始时间升序。
 */
export function buildComingUpDays(events: ComingUpEvent[], nowMs: number): ComingUpDayGroup[] {
  const todayStartMs: number = comingUpDayStartMs(nowMs);
  const todayKey: string = comingUpDateKey(nowMs);
  const groups: Map<string, ComingUpDayGroup> = new Map<string, ComingUpDayGroup>();
  const active: ComingUpEvent[] = events.filter((ev: ComingUpEvent): boolean => ev.endMs > nowMs);
  for (const ev of active) {
    const keyMs: number = Math.max(ev.startMs, todayStartMs);
    const key: string = comingUpDateKey(keyMs);
    let group: ComingUpDayGroup | undefined = groups.get(key);
    if (group === undefined) {
      group = { dateKey: key, dayStartMs: comingUpDayStartMs(keyMs), events: [] };
      groups.set(key, group);
    }
    group.events.push(ev);
  }
  for (const group of groups.values()) {
    group.events.sort((a: ComingUpEvent, b: ComingUpEvent): number => a.startMs - b.startMs);
  }
  const days: ComingUpDayGroup[] = [];
  days.push(groups.get(todayKey) ??
    { dateKey: todayKey, dayStartMs: todayStartMs, events: [] });
  const futureKeys: string[] = Array.from(groups.keys())
    .filter((key: string): boolean => key > todayKey)
    .sort();
  for (const key of futureKeys) {
    const group: ComingUpDayGroup | undefined = groups.get(key);
    if (group !== undefined) {
      days.push(group);
    }
  }
  return days;
}

/**
 * nan.i 复现：把日分组序列切成展示窗口 —— 自每组起始，连续并入直到
 * 达到 3 组或累计事件数将超 10（首个分组无条件并入）。nextDateKey 指向
 * 剩余序列的下一组起始日。
 */
export function buildComingUpWindows(days: ComingUpDayGroup[]): ComingUpWindow[] {
  const windows: ComingUpWindow[] = [];
  let index: number = 0;
  while (index < days.length) {
    const groups: ComingUpDayGroup[] = [];
    let size: number = 0;
    let cursor: number = index;
    while (cursor < days.length) {
      const group: ComingUpDayGroup = days[cursor];
      if (groups.length >= COMING_UP_WINDOW_DAY_LIMIT ||
        (groups.length > 0 && size + group.events.length > COMING_UP_WINDOW_EVENT_LIMIT)) {
        break;
      }
      groups.push(group);
      size += group.events.length;
      cursor++;
    }
    windows.push({
      startDateKey: groups[0].dateKey,
      groups: groups,
      nextDateKey: cursor < days.length ? days[cursor].dateKey : null,
    });
    index = cursor;
  }
  return windows;
}

/** lb2.a 复现：全天恒 UPCOMING；10 分钟内开始 → STARTING_SOON；已开始 → HAPPENING_NOW。 */
export function comingUpEventState(ev: ComingUpEvent, nowMs: number): ComingUpEventState {
  if (ev.isAllDay) {
    return ComingUpEventState.UPCOMING;
  }
  if (nowMs < ev.startMs) {
    return ev.startMs - nowMs <= COMING_UP_STARTING_SOON_MS ?
      ComingUpEventState.STARTING_SOON : ComingUpEventState.UPCOMING;
  }
  return ComingUpEventState.HAPPENING_NOW;
}

/**
 * cbl.e 复现：全天事件在 Android Instances 中以 UTC 午夜表达，显示时换算
 * 为本地当日的 0 点（返回毫秒）。非全天事件原样返回。
 */
export function comingUpAllDayLocalStartMs(ms: number): number {
  const utc: Date = new Date(ms);
  return new Date(utc.getUTCFullYear(), utc.getUTCMonth(), utc.getUTCDate()).getTime();
}
