# Phase 1414：日历权限「Access Required → Go to Settings」对话框移植报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 21 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1414-calendar-access-dialog.md`
- 决策：`docs/migration/adr/ADR-1350-calendar-access-dialog.md`

## 目标

补齐 Phase 1412 Connect 卡授权流的另一半：原版 `oye.n0` 在**永久
拒绝/系统不可再弹**时弹应用内「Access Required」对话框，引导用户
前往系统设置——而非静默停留在 Connect 卡。

## 原版证据链

| 层 | 原版类 | 语义 |
|----|--------|------|
| 枚举 | `iwc` | 权限三元组 `{系统权限, required 标题, rationale 正文}`；READ_CALENDAR → calendar_access_required/rationale |
| 启动器 | `oye.n0` | `jwc` 对话框状态位 + `he0` case12 发起 + `oj1` 结果分发；`jwc.c=true` → `l8n.d` 对话框 |
| 发起分流 | `he0` case12 | 已授权→回调；shouldShowRationale→直接弹对话框；否则系统请求 |
| 拒绝回调 | `oj1`→`he0` case11 | 拒绝后 `!shouldShowRequestPermissionRationale` → `jwc.c=true` 弹框 |
| 对话框 | `l8n.d`+`hwc`+`b8` case9 | 标题/正文 = `iwc.G`/`iwc.H`；Dismiss + Go to Settings |
| 设置出口 | `s86` case19 | `ACTION_APPLICATION_DETAILS_SETTINGS`（应用详情页） |

## Harmony 落点

- `OriginalComingUpCalendarGateway`：`ComingUpCalendarRequestOutcome`
  三态（GRANTED/DENIED_SHOWN/DENIED_HIDDEN），denied 时读
  `PermissionRequestResult.dialogShownResults[0]` 判定系统弹窗是否
  实际弹出（=!shouldShowRationale 等价信号）；新增
  `openComingUpCalendarSettings` = `requestPermissionOnSetting`
  （s86 case19 等价），连同 `ComingUpCalendarSettingsOpener` 注入缝。
- `LibraryPage.connectComingUpCalendar`：GRANTED→重拉；
  DENIED_SHOWN→停留 Connect（原版首次拒绝不打扰）；
  DENIED_HIDDEN→`showCalendarAccessDialog`（promptAction.showDialog，
  标题/正文逐字对齐，按钮 Go to Settings→系统权限页 + Dismiss）。
- 字串：`calendar_access_required`/`calendar_access_rationale`
  en 逐字一致 + zh 本地化；`dismiss`/`go_to_settings` 复用既有。

## 登记差异（ADR-1350）

1. `wa.g0`（rationale 判定）→ `dialogShownResults[0]` 单次调用信号：
   两处触发点收敛为「弹过被拒静默 / 未弹出被拒弹框」，在第二次
   点击 Connect 卡时与原版可观察行为一致。
2. 请求异常 → DENIED_HIDDEN（设置页是唯一可行出路）。
3. 对话框样式以 `showDialog` 标准组件等价 `l8n.d`，同 NotePage
   麦克风权限对话框约定。

## 验收核对

1. ✅ 原版证据：iwc/oye/jwc/he0/oj1/b8/s86/hwc 八类硬钉（fixture 内）。
2. ✅ Harmony 与原版对齐；差异入 ADR-1350。
3. ✅ Replay `d02-original-home-calendar-access-dialog.mjs` +21；
   全量基线绿。
4. ✅ ArkTS 无新增错误（gateway 三处"may throw"为 fail-closed 既定模式）。
5. ✅ `note@default` 与 clean `note@ohosTest` 构建成功。
6. ✅ 本报告 + 三份跟踪文档更新。
