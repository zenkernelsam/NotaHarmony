# ADR-1350 日历权限「Access Required → Go to Settings」对话框

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1414
- 接续：ADR-1348（Coming Up 分区/权限网关）、NotePage 麦克风权限
  对话框既有约定（`microphone_permission_*` + `requestPermissionOnSetting`）
- 证据：`docs/migration/evidence/phase-1414-calendar-access-dialog.md`

## 背景

原版 Connect 卡 onClick = `oye.n0(iwc.READ_CALENDAR, …)`，其完整
语义不止「弹系统授权」：`jwc` 持有对话框可见位 `c`，分流如下——

- 已授权 → granted 回调（重拉事件）；
- `shouldShowRequestPermissionRationale==true` → 直接弹自家
  「Access Required」对话框；
- 否则 → 系统权限请求；拒绝回调（`oj1`→`he0` case11）中
  `!shouldShowRequestPermissionRationale`（永久拒绝/不可再弹）
  → `jwc.c=true` 弹同一对话框。

对话框 = `l8n.d`：标题 `iwc.G`（Calendar Access Required）、正文
`iwc.H`（"…to show your upcoming events. Your calendar is never
changed."）、`Dismiss` + `Go to Settings`（`s86` case19 →
`ACTION_APPLICATION_DETAILS_SETTINGS`）。

Phase 1412 只实现了「点击 → 请求 → 授权则重拉」，永久拒绝路径
缺失对话框引导。

## 决定

1. 网关授权结果升为三态
   `ComingUpCalendarRequestOutcome{GRANTED, DENIED_SHOWN,
   DENIED_HIDDEN}`，以 `PermissionRequestResult.dialogShownResults[0]`
   判定系统弹窗是否实际弹出——Harmony 侧对
   `shouldShowRequestPermissionRationale`/`jwc.c` 的等价信号：
   弹出后被拒 → 静默停留 Connect；未弹出被拒 → 应用内对话框。
2. 对话框用 `promptAction.showDialog`（标题/正文逐字对齐
   `iwc.G`/`iwc.H`，按钮序 Go to Settings→`openComingUpCalendarSettings`
   =`requestPermissionOnSetting`，Dismiss 关闭）——与 NotePage
   麦克风权限对话框同构。
3. 请求通道异常 fail-closed 到 `DENIED_HIDDEN`：此时设置页是唯一
   可行出路，与对话框引导语义一致。
4. `DENIED_SHOWN` 态保留「停留 Connect 卡」（原版首次拒绝不打扰
   语义）。

## 后果

- 永久拒绝后用户不再被困在不可用的 Connect 卡，可经 Go to
  Settings 直达系统权限页——补齐 Phase 1412 的 UX 环路。
- `dialogShownResults` 依赖 API 12+ `PermissionRequestResult`
  可选字段；缺省（旧 API）按 `false` 处理——即更早收敛到设置页
  引导，属安全方向退化。
