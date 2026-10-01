// 原版 jt1/y14 + iwc.READ_CALENDAR 的设备日历读取网关（CalendarKit 移植）。
//
// 证据链（decompiled_1.4.2）：
// - jt1:959  CalendarContract.Instances 窗口查询：今日 0 点 ~ 今日+10 天 0 点，
//            `visible = 1`、`begin ASC`；y14.a() 权限判定 → bh1.isReadable。
// - iwc      READ_CALENDAR 运行时权限；kan.a 的 e7n Connect 卡 =
//            oye.n0(READ_CALENDAR, onDenied, onGranted) 启动器。
// - kg3      ContentObserver 监听 CalendarContract.Events 变更后重新查询；
//            Harmony 无等价全局观察 API → 登记差异：Home 出现时刷新（ADR）。
//
// Harmony 差异：
// - READ_CALENDAR 对应 ohos.permission.READ_WHOLE_CALENDAR（跨应用日历读取，
//   system_basic/user_grant，API 20+ 普通应用可申请）。
// - selfAttendeeStatus=DECLINED 过滤不可移植（calendarManager Event 无
//   自身参与状态字段）→ 文档记录，设备日历的事件可见性交给系统 Provider。
// - 模块级 seam 保持与 OriginalClipboardPermissionGateway 一致，便于
//   Desktop Replay/测试注入桩实现。

import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { calendarManager } from '@kit.CalendarKit';
import {
  ComingUpEvent, ComingUpEventSource, COMING_UP_RANGE_DAYS,
  comingUpAllDayLocalStartMs, comingUpDayStartMs,
} from '../core/model/HomeComingUpModel';

export const READ_WHOLE_CALENDAR_PERMISSION: Permissions =
  'ohos.permission.READ_WHOLE_CALENDAR';

/** bh1 —— CalendarWindow{events, isReadable}。 */
export interface ComingUpCalendarWindow {
  events: ComingUpEvent[];
  isReadable: boolean;
}

export type ComingUpCalendarReadableChecker = () => Promise<boolean>;
export type ComingUpCalendarRequester =
  (context: common.UIAbilityContext) => Promise<ComingUpCalendarRequestOutcome>;
export type ComingUpCalendarSettingsOpener =
  (context: common.UIAbilityContext) => Promise<void>;
export type ComingUpCalendarFetcher =
  (context: common.UIAbilityContext, nowMs: number) => Promise<ComingUpEvent[]>;

/**
 * oye.n0/jwc/he0 case11-12 的三态授权结果：
 * - GRANTED：authResults[0]==PERMISSION_GRANTED → 触发重拉（function1）。
 * - DENIED_SHOWN：系统弹窗确实弹出后被拒绝（dialogShownResults[0]===true）
 *   —— 等价 Android 首次拒绝后 shouldShowRequestPermissionRationale=true，
 *   原版此时不弹自家对话框，停留在 Connect 卡。
 * - DENIED_HIDDEN：系统未再弹出（dialogShownResults[0]===false 或缺省，
 *   即永久拒绝/不可再弹）—— 等价 !shouldShowRequestPermissionRationale，
 *   原版弹「Access Required → Go to Settings」对话框（jwc.c=true→l8n.d）。
 */
export enum ComingUpCalendarRequestOutcome {
  GRANTED = 'granted',
  DENIED_SHOWN = 'denied_shown',
  DENIED_HIDDEN = 'denied_hidden',
}

let readableChecker: ComingUpCalendarReadableChecker = checkReadableWithAccessControl;
let permissionRequester: ComingUpCalendarRequester = requestWithHarmonyAccessControl;
let settingsOpener: ComingUpCalendarSettingsOpener = openSettingsWithAccessControl;
let eventFetcher: ComingUpCalendarFetcher = fetchWithCalendarManager;

export function setComingUpCalendarGatewayForTest(
  checker: ComingUpCalendarReadableChecker,
  requester: ComingUpCalendarRequester,
  fetcher: ComingUpCalendarFetcher,
  opener?: ComingUpCalendarSettingsOpener): void {
  readableChecker = checker;
  permissionRequester = requester;
  eventFetcher = fetcher;
  if (opener !== undefined) {
    settingsOpener = opener;
  }
}

export function resetComingUpCalendarGatewayForTest(): void {
  readableChecker = checkReadableWithAccessControl;
  permissionRequester = requestWithHarmonyAccessControl;
  settingsOpener = openSettingsWithAccessControl;
  eventFetcher = fetchWithCalendarManager;
}

async function checkReadableWithAccessControl(): Promise<boolean> {
  try {
    const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    const status: abilityAccessCtrl.GrantStatus = manager.checkAccessTokenSync(
      info.appInfo.accessTokenId, READ_WHOLE_CALENDAR_PERMISSION);
    return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (e) {
    console.warn(`coming-up calendar access check failed: ${JSON.stringify(e)}`);
    return false;
  }
}

async function requestWithHarmonyAccessControl(
  context: common.UIAbilityContext): Promise<ComingUpCalendarRequestOutcome> {
  const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  const result: PermissionRequestResult = await manager.requestPermissionsFromUser(
    context, [READ_WHOLE_CALENDAR_PERMISSION]);
  if (result.permissions.length === 1 &&
    result.permissions[0] === READ_WHOLE_CALENDAR_PERMISSION &&
    result.authResults.length === 1 &&
    result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
    return ComingUpCalendarRequestOutcome.GRANTED;
  }
  const dialogShown: boolean = result.dialogShownResults !== undefined &&
    result.dialogShownResults.length > 0 && result.dialogShownResults[0] === true;
  return dialogShown ? ComingUpCalendarRequestOutcome.DENIED_SHOWN :
    ComingUpCalendarRequestOutcome.DENIED_HIDDEN;
}

/**
 * s86 case19 等价：原版 Go to Settings = ACTION_APPLICATION_DETAILS_SETTINGS
 * 打开应用详情页；Harmony 对应 requestPermissionOnSetting（直达系统权限页）。
 */
async function openSettingsWithAccessControl(
  context: common.UIAbilityContext): Promise<void> {
  const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  await manager.requestPermissionOnSetting(context, [READ_WHOLE_CALENDAR_PERMISSION]);
}

/**
 * jt1:959 等价：窗口 = [今日 0 点, 今日 + COMING_UP_RANGE_DAYS 天 0 点)。
 * cbl 游标映射：title 空 → ''（渲染层回退 Untitled event）；isAllDay →
 * cbl.e 本地午夜换算；行键 = event id（缺省时 start+index 合成）。
 */
async function fetchWithCalendarManager(
  context: common.UIAbilityContext, nowMs: number): Promise<ComingUpEvent[]> {
  const startMs: number = comingUpDayStartMs(nowMs);
  const endMs: number = comingUpDayStartMs(nowMs) +
    COMING_UP_RANGE_DAYS * 24 * 60 * 60 * 1000;
  const manager: calendarManager.CalendarManager =
    calendarManager.getCalendarManager(context);
  const calendar: calendarManager.Calendar = await manager.getCalendar();
  const filter: calendarManager.EventFilter =
    calendarManager.EventFilter.filterByTime(startMs, endMs);
  const raw: calendarManager.Event[] = await calendar.getEvents(filter,
    ['id', 'title', 'startTime', 'endTime', 'isAllDay']);
  const events: ComingUpEvent[] = [];
  for (let i: number = 0; i < raw.length; i++) {
    const ev: calendarManager.Event = raw[i];
    const isAllDay: boolean = ev.isAllDay === true;
    events.push({
      id: ev.id !== undefined ? String(ev.id) : `event-${ev.startTime}-${i}`,
      title: ev.title !== undefined ? ev.title : '',
      startMs: isAllDay ? comingUpAllDayLocalStartMs(ev.startTime) : ev.startTime,
      endMs: isAllDay ? comingUpAllDayLocalStartMs(ev.endTime) : ev.endTime,
      isAllDay: isAllDay,
      source: ComingUpEventSource.DEVICE,
    });
  }
  return events;
}

/**
 * y14.a() + 查询的合并出口（bh1 等价）：不可读 → isReadable=false 空窗口；
 * 可读但查询失败 → SecurityException/Provider 异常等价：isReadable=true、
 * 事件为空并记日志（原版失败即 break 后仍 emit 当前 list）。
 */
export async function loadComingUpCalendarWindow(
  context: common.UIAbilityContext, nowMs: number): Promise<ComingUpCalendarWindow> {
  let readable: boolean = false;
  try {
    readable = await readableChecker();
  } catch (e) {
    console.warn(`coming-up calendar readable check failed: ${JSON.stringify(e)}`);
  }
  if (!readable) {
    return { events: [], isReadable: false };
  }
  try {
    const events: ComingUpEvent[] = await eventFetcher(context, nowMs);
    return { events: events, isReadable: true };
  } catch (e) {
    console.warn(`coming-up calendar read failed: ${JSON.stringify(e)}`);
    return { events: [], isReadable: true };
  }
}

/** e7n Connect 卡点击 → oye.n0(READ_CALENDAR) 权限请求（三态结果）。 */
export async function requestComingUpCalendarPermission(
  context: common.UIAbilityContext): Promise<ComingUpCalendarRequestOutcome> {
  try {
    return await permissionRequester(context);
  } catch (e) {
    console.warn(`coming-up calendar permission request failed: ${JSON.stringify(e)}`);
    return ComingUpCalendarRequestOutcome.DENIED_HIDDEN;
  }
}

/** b8 case9 → s86 case19：Go to Settings 打开系统权限页。 */
export async function openComingUpCalendarSettings(
  context: common.UIAbilityContext): Promise<void> {
  try {
    await settingsOpener(context);
  } catch (e) {
    console.warn(`coming-up calendar open-settings failed: ${JSON.stringify(e)}`);
  }
}
