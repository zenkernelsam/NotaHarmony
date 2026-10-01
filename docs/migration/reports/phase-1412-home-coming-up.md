# Phase 1412：Library Home "Coming Up" 日历分区移植报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 104 项本 Phase 检查 + 全量基线绿；
  `note@default` / `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1412-home-coming-up.md`
- 决策：`docs/migration/adr/ADR-1348-home-coming-up-calendar.md`

## 目标

补回 1.4.2 原版 Library Home 缺失的 **Coming up** 日历分区
（`vkm.a` 次序：CTA → Coming up → exams → unindexed → favorites →
recents），并接通行内 "Start now" 建笔记。

## 原版证据链

| 层 | 原版类 | 语义 |
|----|--------|------|
| 数据 | `jt1`/`y14`/`cbl`/`bh1` | `Instances` 窗口 `[今日0点,+10天)`、
  `visible=1`、`begin ASC`；`READ_CALENDAR` 检查 → `isReadable`；
  DECLINED 跳过、allDay UTC→本地午夜 |
| 刷新 | `kg3` | `ContentObserver` 监听日历变更重查 |
| 模型 | `m70` case7 → `kb2` | `end>now` → 分组键 `max(start,今日0点)`
  → 组内 begin ASC → 今日组恒在前 + 未来日升序 |
| 行态 | `lb2.a`/`wa2` | allDay→UPCOMING；≤10min→STARTING_SOON；
  已开始→HAPPENING_NOW |
| 面板 | `nan.i`/`za2`/`nan.g`/`nan.j` | ≤3 组≤10 事件分窗；‹/› 翻页
  （earlier/later_days cd、边界禁用）；按起始日记忆选中窗 |
| 行卡 | `nan.a`/`nan.f`/`aa` case2 | accent 竖条卡；副标 All day/SHORT
  时间 + soon/now 前缀；空标题→Untitled event；Start now 钮 |
| 动作 | `ne` case11 → `c13.a` | `ik.CALENDAR` 源，以事件标题建笔记
  并打开（blank→null→默认标题管线） |
| 不可读 | `e7n` | Connect 卡整卡点击 = `oye.n0(READ_CALENDAR)` |
| 空组 | `nan.e`/`adl.b` | "No upcoming events" 卡 |

## Harmony 实现

- `module.json5`：新增 `ohos.permission.READ_WHOLE_CALENDAR`
  （reason + usedScene）。
- `OriginalComingUpCalendarGateway.ets`：`checkAccessTokenSync` 可读
  性检查 + `requestPermissionsFromUser` 授权 + `calendarManager`
  `filterByTime` 10 天窗口查询；`ag1` 字段映射（id/title/start/end/
  allDay，allDay 起止按 `cbl.e` 换算本地午夜）；`ComingUpCalendarWindow`
  = `bh1` 等价；checker/requester/fetcher 三个注入缝。
- `HomeComingUpModel.ets`：`buildComingUpDays`/`buildComingUpWindows`/
  `comingUpEventState`/`comingUpAllDayLocalStartMs` 纯函数 +
  `COMING_UP_*` 常量（10min/10天/≤3组/≤10事件）+ `ComingUpEventSource`
  （DEVICE/SYLLABUS 枚举位）。
- `LibraryPage.ets`：`onPageShow`→`refreshComingUp`（kg3 差异登记，
  见 ADR）；Home 分区渲染 = `HomeComingUpSection`（null 未探测不渲染 /
  false Connect 卡 / true 面板）+ 翻页钮（ToolGlyph chevron + cd +
  边界禁用）+ 日徽标（d + MMM + EEE）+ 事件卡/空组卡 + Start now →
  `createAndLaunch(false,…,titleOverride)`。
- `LibraryViewModel.createNote`：第四参 `titleOverride`（非空直用，
  跳过自动标题工厂——`c13.a` 显式 title 分支语义）。

## 登记差异（ADR-1348）

1. `kg3` 观察者 → Home 呈现刷新（Harmony 无日历全局回调）。
2. `selfAttendeeStatus`/`visible` 过滤不可移植（平台 Provider 约束）。
3. `SYLLABUS` 源 + `q8n.e` 考试卡 → 后端未移植，fail-closed。
4. `f8n.a` 布尔位次序受限 → 按钮恒可点 + 态切换样式实现并登记。
5. 拖拽翻页手势（`nfh.b`）与 `cb2`/`w60` 分析回调不移植。

## 验证

- `docs/migration/replays/d02-original-home-coming-up.mjs`：
  104 检查全绿（原版锚点 37 + Harmony 实现 55 + 字串 24）。
- 全量 Desktop Replay：**1264/1264**。
- `hvigorw --no-daemon assembleHap`：`note@default` 与
  `note@ohosTest` 均 BUILD SUCCESSFUL；无新增错误类告警。
