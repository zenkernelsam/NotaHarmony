# Phase 1414 证据：oye.n0 权限「Access Required → Go to Settings」对话框

- 版本证据基线：`decompiled_1.4.2`
- 接续 Phase 1412：Connect 卡点击只是 `oye.n0` 的前半；本 Phase 补回
  永久拒绝时的应用内引导对话框。

## 1. 权限枚举与启动器（iwc / oye.n0 / jwc）

| 原版 | 语义 | 证据 |
|------|------|------|
| `iwc` 枚举 | 每个权限携带 `{F:系统权限常量, G:required 标题 res, H:rationale 正文 res}`；`READ_CALENDAR` → `calendar_access_required`/`calendar_access_rationale`；`RECORD_AUDIO`/`CAMERA` 同构 | `iwc.java:9-11` |
| `oye.n0(iwc, denied?, granted)` | 组装 `jwc(iwc, granted)` 状态持有者（`c`=`qtg.a(false)` 对话框可见位）+ `he0` case12 发起 lambda + `oj1` 结果回调；`jwc.c==true` → `l8n.d` 渲染对话框 | `oye.java:33156+` |
| `l8n.d` 对话框 | 标题 `d4i.b(w0(jwcVar.a.G))`、正文 `d4i.b(w0(jwcVar.a.H))`、按钮 `Dismiss`（`hwc`/`o9n.a`）与 `Go to Settings`（内容 lambda `b8(bz5,context,jwc)`） | `oye.java:33244-33310` |

## 2. 发起与回调分流（he0 case12 / oj1 / he0 case11）

| 原版 | 语义 | 证据 |
|------|------|------|
| `he0` case12 | 点击时：`dbj.n(ctx,perm)==0`（已授权）→ `granted()`；否则 `wa.g0(activity,perm)`（shouldShowRequestPermissionRationale）→ `jwc.c=true`（直接弹自家对话框）；否则 `bz5.invoke(perm)` 发系统请求 | `he0.java:181-198` |
| `oj1` | 系统请求结果布尔分发：授权 → `function1`（granted，重拉）；拒绝 → `function0`（=he0 case11 lambda） | `oj1.java:24-38` |
| `he0` case11 | 拒绝回调：先调外层回调；随后 `!wa.g0(activity,perm)`（rationale 已不可展示 = 永久拒绝）→ `jwc.c=true` → 对话框出现 | `he0.java:164-178` |
| `b8` case9 | 「Go to Settings」钮 → `s86` case19 | `b8.java:256-275` |
| `s86` case19 | `bz5.invoke(new Intent("android.settings.APPLICATION_DETAILS_SETTINGS", Uri.fromParts("package", pkg)))` | `s86.java:221` |

净语义：**首次拒绝不打扰**（系统弹窗已展示，停留 Connect 卡）；
**当系统不再展示授权框时**（永久拒绝/策略限制）Connect 卡点击或
拒绝回调会转为「Access Required → Go to Settings」对话框。

## 3. Harmony 对应

| 原版 | Harmony | 落点 |
|------|---------|------|
| `wa.g0`=shouldShowRationale / 系统可否再弹 | `PermissionRequestResult.dialogShownResults[0]`——本次调用系统弹窗是否实际弹出；`false`+denied = 不可再弹 | `OriginalComingUpCalendarGateway.requestWithHarmonyAccessControl` |
| `jwc.c` 三态分流 | `ComingUpCalendarRequestOutcome{GRANTED, DENIED_SHOWN, DENIED_HIDDEN}` | 同上 |
| `s86` case19 `APPLICATION_DETAILS_SETTINGS` | `atManager.requestPermissionOnSetting(ctx,[perm])` 直达系统权限页 | `openSettingsWithAccessControl`（`ComingUpCalendarSettingsOpener` 注入缝） |
| `l8n.d` 对话框 | `promptAction.showDialog{title:calendar_access_required, message:calendar_access_rationale, buttons:[Go to Settings, Dismiss]}`；确认 → `openComingUpCalendarSettings` | `LibraryPage.showCalendarAccessDialog` |

## 4. 登记差异

1. Android 把「tap 时 rationale=true → 直接弹自家框」与「拒绝后
   rationale=false → 弹框」分两处触发；Harmony 以单次调用的
   `dialogShownResults` 统一：弹窗展示过被拒→静默，未弹出被拒→
   对话框。两映射在「第二次点击 Connect 卡」时收敛到同一可观察
   行为（首次点击：系统框；第二次：应用内对话框）。
2. 请求异常（非拒绝）fail-closed 为 `DENIED_HIDDEN`——此时系统
   请求通道已坏，设置页是唯一可用出路，与原对话框语义一致。
3. `l8n.d` 的 Compose 对话框布局细节（标题排版/按钮次序）以
   `promptAction.showDialog` 标准样式等价，沿用 NotePage 麦克风
   权限对话框既有约定（同 `iwc` 枚举的 RECORD_AUDIO 分支已在
   编辑器路径先行落地）。
