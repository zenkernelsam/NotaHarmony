// Phase 1412 — Library Home "Coming Up" 设备日历分区
// （jt1/y14 权限+查询 + cbl 游标映射 + m70 case7 分组 + lb2.a 行状态 +
// nan.i za2 窗口 + nan.c/d/e/f/g 渲染 + kan.a 宿主 + e7n Connect 卡 +
// ne case11 事件行建笔记），decompiled_1.4.2 证据。
//
// 原版证据（decompiled_1.4.2）：
//   jt1:959  CalendarContract.Instances 窗口 [今日0点, +10天0点)
//            `visible=1` + `begin ASC`；SecurityException/Provider 异常 → break。
//   y14.a()  READ_CALENDAR 权限检查 → bh1(events, isReadable)。
//   cbl:~195 游标→ag1：selfAttendeeStatus==2(ATTENDEE_DECLINED) 跳过；
//            title 空→''(渲染层 Untitled 回退)；allDay → cbl.e UTC→本地午夜。
//   m70 case7 过滤 end>now → 分组键 max(start, 今日0点) 本地日期 →
//            组内 begin ASC → [今日组(可空)] + 未来日升序。
//   lb2.a    allDay→UPCOMING；start-now≤10min→STARTING_SOON；now≥start→
//            HAPPENING_NOW。
//   nan.i    za2 窗口：≤3 组且 ≤10 事件（首组无条件并入）；rga 选中窗口
//            起始日；nan.j ‹/› 边界由 nan.g enabled 置灰。
//   nan.d    日徽标 d/MMM/EEE；nan.e/adl.b 空组卡 "No upcoming events"；
//   nan.b    组间 1dp 分隔。
//   nan.f/aa 事件行：副标 = allDay→"All day" 或 SHORT 时间，soon/now 包
//            "%1$s • Starting soon"/"%1$s • Happening now" 并改色；
//            标题空 → untitled_event；尾部 "Start now" 钮（样式按态切换）。
//   ne case11→c13.a(…, ik.CALENDAR, title, …)：Start now → 以事件标题
//            建笔记（标题空→null→默认标题管线）后导航打开。
//   e7n      不可读 → Connect 卡(connect_title/subtitle) 整卡点击 =
//            oye.n0(iwc.READ_CALENDAR) 权限请求。
//   kg3      ContentObserver → 日历变更重查（Harmony 无等价 → Home 呈现刷新）。
// Harmony：module.json5 READ_WHOLE_CALENDAR；OriginalComingUpCalendarGateway
//   （checker/requester/fetcher 注入缝 + filterByTime 10 天窗 + cbl 映射）；
//   HomeComingUpModel（m70/lb2/nan.i 纯逻辑）；LibraryPage Home 分区 +
//   Connect 卡 + 分页器 + 行卡 + Start now→createAndLaunch(titleOverride)。

import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const model = readFileSync('note/src/main/ets/core/model/HomeComingUpModel.ets', 'utf8');
const gateway = readFileSync('note/src/main/ets/data/OriginalComingUpCalendarGateway.ets', 'utf8');
const lib = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const vm = readFileSync('note/src/main/ets/ui/library/LibraryViewModel.ets', 'utf8');
const moduleJson = readFileSync('note/src/main/module.json5', 'utf8');
const baseStr = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStr = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

// ── 反编译证据锁定 ──
const root = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/';
const jt1 = readFileSync(`${root}sources/defpackage/jt1.java`, 'utf8');
const cbl = readFileSync(`${root}sources/defpackage/cbl.java`, 'utf8');
const m70 = readFileSync(`${root}sources/defpackage/m70.java`, 'utf8');
const lb2 = readFileSync(`${root}sources/defpackage/lb2.java`, 'utf8');
const nan = readFileSync(`${root}sources/defpackage/nan.java`, 'utf8');
const kan = readFileSync(`${root}sources/defpackage/kan.java`, 'utf8');
const e7n = readFileSync(`${root}sources/defpackage/e7n.java`, 'utf8');
const ne = readFileSync(`${root}sources/defpackage/ne.java`, 'utf8');
const aa = readFileSync(`${root}sources/defpackage/aa.java`, 'utf8');
const origStr = readFileSync(`${root}resources/res/values/strings.xml`, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 原版证据：查询窗口/权限/映射 ──
check(/Instances\.CONTENT_URI\.buildUpon\(\)[\s\S]*?plusDays\(10L\)[\s\S]*?\.build\(\)/.test(jt1),
  'jt1: Instances 窗口 = [今日0点, +10天0点)');
check(jt1.includes('"visible = 1"'), 'jt1: visible=1 过滤');
check(jt1.includes('"begin ASC"'), 'jt1: begin ASC 排序');
check(jt1.includes('new bh1(list2, y14Var.a())'), 'jt1: bh1{events, isReadable=权限}');
check(cbl.includes('"title"') && cbl.includes('"begin"') && cbl.includes('"end"') &&
  cbl.includes('"allDay"') && cbl.includes('"selfAttendeeStatus"'),
  'cbl projection: title/begin/end/allDay/selfAttendeeStatus');
check(/getInt\(columnIndexOrThrow12\) == 2/.test(cbl),
  'cbl: selfAttendeeStatus==2(ATTENDEE_DECLINED) 跳过');
check(/if \(z\) \{\s*Instant instant = Instant\.ofEpochMilli\(j\)\.atZone\(ZoneId\.of\("UTC"\)\)\.toLocalDate\(\)\.atStartOfDay\(zoneId\)/.test(cbl),
  'cbl.e: allDay UTC→本地午夜换算');

// ── 原版证据：分组/状态/窗口 ──
check(/\.e\.compareTo\(instant\) > 0/.test(m70), 'm70 case7: 过滤 end>now');
check(/sgn\.W\(instant2, instant3\)/.test(m70), 'm70 case7: 分组键 max(start, 今日0点)');
check(m70.includes('compareTo((ChronoLocalDate) localDate) > 0'),
  'm70 case7: 未来日组只收 >today');
check(m70.includes('new kb2('), 'm70 case7: 产出 kb2{days,isReadable,now,zone}');
check(lb2.includes('Duration.ofMinutes(10L)'), 'lb2.a: starting-soon 阈值 10 分钟');
check(/if \(z\) \{\s*return wa2Var;/.test(lb2) && /instant\.isBefore\(instant2\)/.test(lb2),
  'lb2.a: allDay→UPCOMING / now<start 阈值比较 / else HAPPENING_NOW');
check(/arrayList3\.size\(\) >= 3 \|\| xa2Var2\.b\.size\(\) \+ size > 10/.test(nan),
  'nan.i: 窗口 ≤3 组且 ≤10 事件');
check(nan.includes('comingUpEarlierDaysButton') && nan.includes('comingUpLaterDaysButton'),
  'nan.g: ‹/› 翻页钮 testTag');
check(nan.includes('home_coming_up_earlier_days') && nan.includes('home_coming_up_later_days'),
  'nan.g: ‹/› 无障碍标签');
check(nan.includes('"comingUpPanel"') && nan.includes('"comingUpEventRow:"'),
  'nan.i/f: 面板与行 testTag');
check(nan.includes('DateTimeFormatter.ofPattern("MMM"') &&
  nan.includes('DateTimeFormatter.ofPattern("EEE"') &&
  nan.includes('DateTimeFormatter.ofPattern("d"'),
  'nan.d: d/MMM/EEE 日徽标');
check(nan.includes('ofLocalizedTime(FormatStyle.SHORT)'),
  'nan.f: 事件行 SHORT 本地化时间');
check(nan.includes('home_coming_up_starting_soon') &&
  nan.includes('home_coming_up_happening_now') &&
  nan.includes('home_coming_up_all_day'),
  'nan.f: starting_soon/happening_now/all_day 文案');
check(aa.includes('home_coming_up_untitled_event'), 'aa case2: 空标题回退 untitled_event');
check(aa.includes('start_now') || aa.includes('adl.a'), 'aa case2: Start now 内容');
check(ne.includes('ik.CALENDAR'), 'ne case11: 事件行 c13.a(ik.CALENDAR) 建笔记');
check(/str3 == null \|\| r0h\.T0\(str3\)/.test(ne),
  'ne case11: 标题空→null（默认标题管线）');
check(kan.includes('kb2Var.b') && kan.includes('nan.i(') && kan.includes('e7n.a('),
  'kan.a: readable→nan.i 面板 / else→e7n Connect 卡');
check(kan.includes('iwc.READ_CALENDAR'), 'kan.a: Connect → oye.n0(READ_CALENDAR)');
check(e7n.includes('home_coming_up_connect_title') &&
  e7n.includes('home_coming_up_connect_subtitle'), 'e7n: Connect 卡文案');

// ── 原版字串值锁定 ──
check(origStr.includes('<string name="feature_library__home_coming_up_title">Coming up</string>'),
  '原版 coming_up_title');
check(origStr.includes('<string name="feature_library__home_coming_up_happening_now">%1$s • Happening now</string>'),
  '原版 happening_now 格式');
check(origStr.includes('<string name="feature_library__home_coming_up_starting_soon">%1$s • Starting soon</string>'),
  '原版 starting_soon 格式');
check(origStr.includes('<string name="feature_library__home_coming_up_no_events">No upcoming events</string>'),
  '原版 no_events');
check(origStr.includes('<string name="feature_library__home_coming_up_start_now">Start now</string>'),
  '原版 start_now');
check(origStr.includes('<string name="feature_library__home_coming_up_untitled_event">Untitled event</string>'),
  '原版 untitled_event');
check(origStr.includes('<string name="feature_library__home_coming_up_connect_title">Events at a glance</string>'),
  '原版 connect_title');

// ── Harmony：权限声明 + 网关 ──
check(moduleJson.includes('ohos.permission.READ_WHOLE_CALENDAR'),
  'module.json5: READ_WHOLE_CALENDAR 声明');
check(moduleJson.includes('read_calendar_permission_reason'),
  'module.json5: 日历权限 reason');
check(gateway.includes("READ_WHOLE_CALENDAR_PERMISSION: Permissions =\n  'ohos.permission.READ_WHOLE_CALENDAR'"),
  'gateway: 权限常量');
check(gateway.includes('checkAccessTokenSync') && gateway.includes('accessTokenId'),
  'gateway: y14.a() 等价 checkAccessTokenSync');
check(gateway.includes('requestPermissionsFromUser'),
  'gateway: oye.n0 等价 requestPermissionsFromUser');
check(/EventFilter\.filterByTime\(startMs, endMs\)/.test(gateway),
  'gateway: filterByTime 窗口查询');
check(gateway.includes('COMING_UP_RANGE_DAYS * 24 * 60 * 60 * 1000'),
  'gateway: 10 天窗口（jt1 plusDays(10)）');
check(gateway.includes('getEvents(filter,') &&
  gateway.includes("'id', 'title', 'startTime', 'endTime', 'isAllDay'"),
  'gateway: getEvents 投影字段');
check(gateway.includes('comingUpAllDayLocalStartMs(ev.startTime)') &&
  gateway.includes('comingUpAllDayLocalStartMs(ev.endTime)'),
  'gateway: allDay 起止均按 cbl.e 换算');
check(gateway.includes('ComingUpEventSource.DEVICE'), 'gateway: zf1.DEVICE 来源');
check(gateway.includes('setComingUpCalendarGatewayForTest'),
  'gateway: 测试注入缝');
check(/isReadable: false/.test(gateway) && /isReadable: true/.test(gateway),
  'gateway: bh1 isReadable 两态');

// ── Harmony：纯模型 ──
check(model.includes('COMING_UP_STARTING_SOON_MS: number = 10 * 60 * 1000'),
  'model: lb2.a 10 分钟阈值');
check(model.includes('COMING_UP_RANGE_DAYS: number = 10'), 'model: 10 天窗口常量');
check(model.includes('COMING_UP_WINDOW_DAY_LIMIT: number = 3') &&
  model.includes('COMING_UP_WINDOW_EVENT_LIMIT: number = 10'),
  'model: za2 ≤3组≤10事件 常量');
check(/ev\.endMs > nowMs/.test(model), 'model: end>now 过滤');
check(/Math\.max\(ev\.startMs, todayStartMs\)/.test(model),
  'model: 分组键 max(start, 今日0点)');
check(model.includes('a.startMs - b.startMs'), 'model: 组内 begin ASC');
check(/days\.push\(groups\.get\(todayKey\) \?\?/.test(model),
  'model: 今日组恒在首位（可为空）');
check(/key > todayKey/.test(model), 'model: 未来日组 >today');
check(/groups\.length >= COMING_UP_WINDOW_DAY_LIMIT \|\|[\s\S]*?size \+ group\.events\.length > COMING_UP_WINDOW_EVENT_LIMIT/.test(model),
  'model: 窗口分块 ≤3组/≤10事件');
check(model.includes('startDateKey') && model.includes('nextDateKey'),
  'model: za2{startDateKey,nextDateKey}');
check(/if \(ev\.isAllDay\)[\s\S]*?return ComingUpEventState\.UPCOMING/.test(model),
  'model: allDay→UPCOMING');
check(/ev\.startMs - nowMs <= COMING_UP_STARTING_SOON_MS[\s\S]*?STARTING_SOON/.test(model),
  'model: ≤10min→STARTING_SOON');
check(model.includes('return ComingUpEventState.HAPPENING_NOW'),
  'model: 已开始→HAPPENING_NOW');
check(model.includes("SYLLABUS = 'syllabus'"), 'model: zf1.SYLLABUS 枚举位（文档化未用）');

// ── Harmony：页面接线 ──
check(lib.includes('this.HomeComingUpSection()'), 'LibraryPage: ComingUp 分区挂载');
check(lib.includes('this.refreshComingUp(lifecycleGeneration)'),
  'LibraryPage: onPageShow→refreshComingUp（kg3 差异登记）');
check(lib.includes('loadComingUpCalendarWindow(context, Date.now())'),
  'LibraryPage: 网关装载');
check(lib.includes('buildComingUpDays(window.events, nowMs)') &&
  lib.includes('buildComingUpWindows(days)'),
  'LibraryPage: m70→nan.i 管线');
check(lib.includes('comingUpReadable') && lib.includes('ComingUpConnectCard()') &&
  lib.includes('ComingUpPanel()'),
  'LibraryPage: kan.a 双态（Connect 卡 / 面板）');
check(lib.includes('requestComingUpCalendarPermission(context)'),
  'LibraryPage: Connect 卡 → 权限请求');
check(lib.includes("ComingUpPagerButton('chevron_left'") &&
  lib.includes("ComingUpPagerButton('chevron_right'"),
  'LibraryPage: nan.g ‹/› 翻页钮');
check(lib.includes('comingUpWindowIndex() > 0') &&
  lib.includes('comingUpWindowIndex() + 1 < this.comingUpWindows.length'),
  'LibraryPage: nan.j 边界禁用');
check(lib.includes('windows[next].startDateKey'),
  'LibraryPage: rga 选中窗口起始日');
check(lib.includes('home_coming_up_earlier_days') &&
  lib.includes('home_coming_up_later_days'),
  'LibraryPage: 翻页钮无障碍标签');
check(lib.includes('home_coming_up_no_events'), 'LibraryPage: 空组 nan.e 卡');
check(lib.includes('home_coming_up_untitled_event'),
  'LibraryPage: 空标题回退');
check(lib.includes("timeStyle: 'short'"), 'LibraryPage: SHORT 时间格式化');
check(lib.includes("month: 'short'") && lib.includes("weekday: 'short'"),
  'LibraryPage: nan.d MMM/EEE 徽标');
check(lib.includes('home_coming_up_starting_soon') &&
  lib.includes('home_coming_up_happening_now') &&
  lib.includes('home_coming_up_all_day'),
  'LibraryPage: 行状态文案');
check(lib.includes('home_coming_up_start_now') &&
  lib.includes('openComingUpEventNote(ev)'),
  'LibraryPage: Start now → 事件笔记');
check(/titleOverride\?: string/.test(lib) &&
  /vm\.createNote\(this\.searchText, templateOverride, folderId,\s*\n?\s*titleOverride\)/.test(lib),
  'LibraryPage: createAndLaunch titleOverride 透传');
check(/titleOverride !== undefined\)\s*\{?\s*title = titleOverride/.test(vm),
  'VM: c13.a title 直给分支');
check(lib.includes('Divider()'), 'LibraryPage: nan.b 组间分隔线');

// ── Harmony：字串 ──
for (const key of ['home_coming_up_title', 'home_coming_up_connect_title',
  'home_coming_up_connect_subtitle', 'home_coming_up_start_now',
  'home_coming_up_no_events', 'home_coming_up_all_day',
  'home_coming_up_starting_soon', 'home_coming_up_happening_now',
  'home_coming_up_earlier_days', 'home_coming_up_later_days',
  'home_coming_up_untitled_event', 'read_calendar_permission_reason']) {
  check(baseStr.includes(`"name": "${key}"`), `base 字串 ${key}`);
  check(zhStr.includes(`"name": "${key}"`), `zh 字串 ${key}`);
}
check(baseStr.includes('%1$s • Starting soon') && zhStr.includes('%1$s • '),
  'starting_soon 参数字串');

console.log(`PASS home-coming-up (${n} checks)`);
