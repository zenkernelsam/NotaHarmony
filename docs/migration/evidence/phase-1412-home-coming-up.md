# Phase 1412 证据：Library Home "Coming Up" 设备日历分区

- 版本证据基线：`decompiled_1.4.2`（源码区 `sources/defpackage/` + `resources/res/values/strings.xml`）
- 本 Phase 只读原版产物；Harmony 实现全部落在 `C:\HarmonyProject\NotaHarmony`。

## 1. 数据获取链（jt1 / y14 / cbl / bh1 / kg3）

| 原版类 | 行为 | 证据 |
|--------|------|------|
| `jt1` case2 | `CalendarContract.Instances.CONTENT_URI` 追加 `[today.atStartOfDay(zone), today+10d.atStartOfDay(zone)]` 路径段，`projection=cbl.a`，`selection="visible = 1"`，`sortOrder="begin ASC"`；`SecurityException`/`IllegalStateException`/provider 拒绝 → 记日志后 break（emit 当前 list） | `jt1.java:959` |
| `y14.a()` | `checkSelfPermission(READ_CALENDAR)` → `bh1{events, isReadable}` | `jt1.java:1025` |
| `cbl` | 游标→`ag1` 映射：`selfAttendeeStatus==2`(ATTENDEE_DECLINED) 跳过；`title` 空/null → `''`；`rrule`/`rdate`/`originalInstanceTime` → recurring+实例键；`allDay==1` → `cbl.e`：UTC 午夜→`localZone` 当日 0 点（begin/end 均换算） | `cbl.java:195-243` |
| `kg3` | `ContentObserver` 注册在 `CalendarContract.Events` → 变更即重发查询 | `kg3.java` |
| `bh1` | `CalendarWindow{events:List, isReadable:Boolean}` | `bh1.java` |
| `iwc` | `READ_CALENDAR` 权限常量；`oye.n0(iwc.READ_CALENDAR, denied, granted)` = rememberLauncher 包装 | `kan.java:44` |

## 2. 模型变换（m70 case7 / lb2 / xa2 / za2 / kb2 / wa2 / zf1 / ag1）

| 原版 | 语义 | 证据 |
|------|------|------|
| `m70` case7 | ① `event.e > now` 过滤未结束；② 分组键 `max(event.d, today.atStartOfDay)` 的 `LocalDate`（跨日仍在进行 → 归"今天"）；③ 组内 `cw2(19)` = begin 升序（cursor `begin ASC` 同序）；④ `kb2` = `[xa2(today, list or empty)] + futureGroups(date>today, TreeMap 升序)` | `m70.java:257-313` |
| `lb2.a` | `isAllDay → UPCOMING`；`now<start` 且 `start-now ≤ 10min` → `STARTING_SOON`；否则 `now≥start → HAPPENING_NOW` | `lb2.java:16-39`（`Duration.ofMinutes(10)`） |
| `ag1` | `{a:id(title?:eventId), b:instanceTime, c:title, d:begin, e:end, f:calendarId, g:displayColor, h:allDay, i:recurring, j:zf1 来源, k:folderRef, l:isExam}` | `ag1.java:6-34` |
| `zf1` | `DEVICE` / `SYLLABUS`（`jt1:1589` 合流 `lhh` 课表条目，含 `EXAM` 标签与文件夹引用） | `zf1.java`、`jt1.java:1560-1600` |
| `xa2` | `{a:LocalDate, b:List<ag1>}` 日分组 | `xa2.java` |
| `za2` | `{a:startDate, b:groups, c:nextStartDate}` 展示窗口 | `nan.java:510-575` |

## 3. 渲染（kan.a / nan.* / e7n / aa case2 / ne case11）

| 原版 | 语义 |
|------|------|
| `kan.a` | `kb2.b` 可读 → `nan.i` 面板；不可读 → `e7n` Connect 卡。`else` 分支内嵌"有事件仍渲染面板"的死代码（权限缺失时 `bh1` 恒空表，实际不可达）→ 等价 = 不可读恒 Connect 卡 |
| `nan.i` | 预计算 `za2` 窗口链：自首组起每窗并到 `<3 组` 或 `累计>10 事件` 为止（首组无条件并入——单日超限仍独占一窗）；`rga` 记忆当前窗口起始日；`g()` 头部 + 组间 `nan.b` 1dp 分隔 + 每组 `nan.c`；`nfh.b/jb2` 拖拽手势同 `nan.j` 切窗（cb2 埋点不移植） |
| `nan.g` | "Coming up" 标题(weight) + `chevron_left`(cd=earlier_days, enabled=i>0) + `chevron_right`(cd=later_days, enabled=i+1<size) |
| `nan.c` | Row：日徽标 `d()` + 事件列（无事件 → `nan.e` 空卡） |
| `nan.d` | Row：`d`(大号) + `MMM` + `EEE`（locale-aware `ofPattern`） |
| `nan.e`/`adl.b` | `nan.a` 卡面 + "No upcoming events" |
| `nan.a` | 卡面 = `surface` + 3dp accent 竖条 + padding 16/12 |
| `nan.f` | 行副标：`allDay→"All day"` else `ofLocalizedTime(SHORT).format(start)`；`STARTING_SOON`/`HAPPENING_NOW` 分别包装 `%1$s • Starting soon`/`%1$s • Happening now` 且副标改色（`a.d.a` vs `a.c.c`） |
| `aa` case2 | 行体 = 副标 + 标题（`ag1.c` blank → `home_coming_up_untitled_event`）+ `f8n.a` 按钮内容 `adl.a` = "Start now" 文本；样式 `lma.F`（非 UPCOMING）/`lma.J`（UPCOMING）切换 |
| `ne` case11 | 行按钮 → `c13.a(z(),H,K,S,N, cp5.b, ik.CALENDAR, !z2, titleOrNull, bz5)` → `e28` 用例 `.t0(b29)` = **以事件标题建笔记并打开**（标题 blank → null → 默认标题管线） |
| `e7n` | Connect 卡 = `o8n.c(connect_title, "comingUpConnectCard", connect_subtitle, …, onClick)` 整卡可点 |
| `vkm.a` | Home 序：CTA → `kan.a` → `q8n.e`(exams) → `vkm.e`(unindexed) → favorites → recents |

## 4. 原版字串（`feature_library__home_coming_up_*`）

`title`=Coming up；`connect_title`=Events at a glance；`connect_subtitle`=See today's classes, study reminders, and linked notes in one place.；`start_now`=Start now；`no_events`=No upcoming events；`all_day`=All day；`starting_soon`=`%1$s • Starting soon`；`happening_now`=`%1$s • Happening now`；`earlier_days`=Show earlier days；`later_days`=Show later days；`untitled_event`=Untitled event。

## 5. Harmony 移植落点

- `module.json5`：`ohos.permission.READ_WHOLE_CALENDAR`（`iwc.READ_CALENDAR` 的 Harmony 对应，system_basic/user_grant）+ `read_calendar_permission_reason`。
- `OriginalComingUpCalendarGateway.ets`：`checkAccessTokenSync`（=`y14.a()`）+ `requestPermissionsFromUser`（=`oye.n0`）+ `calendarManager.getCalendarManager(ctx).getCalendar().getEvents(EventFilter.filterByTime(today0, today0+10d))`（=`jt1` 窗口）+ 字段映射 `id/title/startTime/endTime/isAllDay`（allDay 起止按 `cbl.e` 换算）；`bh1` 等价 `ComingUpCalendarWindow{events,isReadable}`；checker/requester/fetcher 三处注入缝（沿用 `OriginalClipboardPermissionGateway` 约定）。
- `HomeComingUpModel.ets`：`buildComingUpDays`（m70 case7）+ `buildComingUpWindows`（nan.i za2 分窗）+ `comingUpEventState`（lb2.a）+ `comingUpAllDayLocalStartMs`（cbl.e）+ 常量组。
- `LibraryPage.ets`：`onPageShow`→`refreshComingUp`（kg3 差异登记）；`HomeComingUpSection`/`ComingUpPanel`/`ComingUpPagerButton`/`ComingUpDayBlock`/`ComingUpDayBadge`/`ComingUpEmptyCard`/`ComingUpEventCard`/`ComingUpConnectCard`；`createAndLaunch(..., titleOverride)` + `vm.createNote(..., titleOverride)`（ne case11→c13.a 直给标题、跳自动标题工厂）。

## 6. 登记差异（见 ADR-1348）

1. `kg3` ContentObserver 实时重查 → Harmony 无等价系统回调，改为 `onPageShow`/`loadNotes` 完成时刷新 + Connect 授权成功后重拉。
2. `selfAttendeeStatus=DECLINED` 与 `visible=1` 过滤 → `calendarManager` 无自身参与状态/可见性字段，由系统 Provider 等价约束。
3. `SYLLABUS` 事件源（后端课表/考试 `lhh`）与 `q8n.e` 考试卡 → 无本地数据源，fail-closed；枚举位保留。
4. `f8n.a` 布尔位次序经脱壳可读性受限 → 以"按钮可点 + 态切换样式"实现并登记。
5. 事件行拖拽手势（`nfh.b/jb2`）与 `cb2`/`w60` 埋点回调不移植（分析/手势装饰，非功能差异）。
