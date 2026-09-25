# 原版 MainActivity 属性级证据（decompiled_1.0.3 manifest）

日期：2026-09-25。`MainActivity` 元素体逐项核对。

## 属性逐项

| 原版属性 | 语义 | Harmony 归属 |
|---|---|---|
| `exported=true` | 接收外部 intent | `NoteAbility.exported=true` + skills 在位。 |
| `configChanges=smallestScreenSize\|screenSize\|screenLayout\|orientation\|navigation\|keyboardHidden\|keyboard` | 旋转/键盘/导航键不自毁重建 | Harmony Ability 本就无 Android 式重建；`onConfigurationUpdate` 已承载深色模式切换——语义等价。 |
| `windowSoftInputMode=adjustNothing` | 软键盘不挤压/不平移窗口——原版编辑器靠 Compose `WindowInsets.ime` 自管 inset（文本块工具条随键盘上浮） | **登记差异**：Harmony 侧无逐组件 IME-inset 自管链路，`TextBlockOverlay` 为底部锚定布局、不读键盘高；采用系统 `KeyboardAvoidMode.OFFSET`（缺省），聚焦输入框由系统上托保证可见。全局改 `NONE` 会令对话框/输入项被键盘覆盖，故不移植——等价语义由系统避让承担。 |
| `resizeableActivity=true` | 多窗口支持 | Harmony 平板原生多窗口，无需声明。 |
| `showWhenLocked=true`+`turnScreenOn=true` | 锁屏上直接起新建笔记（配 `LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE` 特权权限，Samsung 熄屏速写同源） | HarmonyOS 无三方"锁屏上展示/点亮屏幕拉起"公开 API——Samsung/系统级集成边界。 |
| `meta-data android.activity.launch_mode=singleInstancePerTask` | 每次启动建独立 task、task 内单例（多文档窗口模型） | Harmony `launchType` 无 per-task 语义；当前 singleton + `onNewWant` 统一入队（enqueueSharedWantUris/DeepLink/OpenTarget）路由到唯一窗口——单窗口多文档模型，登记差异。 |

## intent-filter 逐项（在 activity 内）

| filter | 归属 |
|---|---|
| MAIN+LAUNCHER+DEFAULT | `ohos.want.action.home` + entity.system.home skill 在位。 |
| CREATE_NOTE+DEFAULT | `hv7.i` 入口：CREATE_NOTE 或 widget extra 或 `/app/note` 深链 → `Q.j=true`（直接打开态）；Harmony 由 `LaunchActionIngress` 卡片/快捷方式 `launch_action` 等价；系统级公共 action 无 Harmony 对应 want → 边界记录。 |
| VIEW http(s) `notability.com` + `*.notability.com`，pathPrefix `/authlink`、`/app/note`，path `/event/learn-from-home`、`/event/plus25`（autoVerify） | `py2.d`：`/app/note/<id>` 按段数校验（size==3、`/app/note` 前缀）→ `py2.b` 取末段 `wtf.f` 解析 note id → `DeepLinkIngress`+`resolveDeepLinkNoteId` 已移植（含 `*.notability.com` 通配在 Harmony 由 `host`+pathStartWith 表达，已声明）。`/authlink`（`py2.c`→userId+linkUUID 登录回流）与 `/event/*`（营销事件页）→登录/Learn 边界（ADR-0662/0652）。autoVerify App Links 验证为 Play/平台机制→边界。 |
| VIEW content\|file `application/pdf` | `viewData` skill + `file:application/pdf` uri 已声明。 |
| SEND `application/pdf` | `sendData` skill + `file:application/pdf` 已声明；`sendMultipleData` 额外覆盖（原版未声明 SEND_MULTIPLE，Harmony 为增强覆盖，登记）。 |

## 结论

MainActivity 属性级全部有归属：exported/configChanges/resizeable
语义等价，adjustNothing 与 singleInstancePerTask 为登记差异
（系统避让/单窗口模型），showWhenLocked+turnScreenOn+
LAUNCH_CAPTURE 为 Samsung/系统边界；深链矩阵 `/app/note` 已移植、
`/authlink`+`/event/*` 边界。
