# ADR-0679 MainActivity 属性级审计收口

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：731
- 证据：`docs/migration/evidence/original-manifest-activity-attrs-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-manifest-activity-attrs.mjs`
- 接续：ADR-0677（manifest 组件级审计）

## 背景

`MainActivity` 元素属性与 5 条 intent-filter 逐项核对——manifest
审计最后一块拼图。

## 决策

### 语义等价（无需变更）

- `exported` → `exported:true`+skills；`configChanges` 全量集 →
  Harmony Ability 无重建语义（`onConfigurationUpdate` 已承载深色
  切换）；`resizeableActivity` → 平板原生多窗口。
- `/app/note` 深链（autoVerify、`*.notability.com`）→
  `DeepLinkIngress`/`resolveDeepLinkNoteId` 已移植，skills 已声明。

### 登记差异（不改行为）

- `windowSoftInputMode=adjustNothing`：原版编辑器以 Compose
  `WindowInsets.ime` 自管 inset（文本工具条随键盘浮起），Harmony
  无该逐组件链路；保持系统 `KeyboardAvoidMode.OFFSET`——聚焦输入
  由系统上托保证可见。全局 `NONE` 会令库/设置页对话框输入被键盘
  覆盖，故不改（差异项登记，非缺陷）。
- `singleInstancePerTask`：Harmony `launchType` 无 per-task 语义；
  singleton+`onNewWant` 入队路由=单窗口多文档模型，登记差异。
- `sendMultipleData` 为 Harmony 侧增强覆盖（原版仅声明 SEND）；
  CREATE_NOTE 系统级 action 无 Harmony 公共 want 对应，其应用内
  路径由 `launch_action` 等价承载。

### 边界登记

- `showWhenLocked`+`turnScreenOn`+`LAUNCH_CAPTURE_CONTENT_ACTIVITY_
  FOR_NOTE`：锁屏速写为 Samsung/系统特权集成，Harmony 无公开等价。
- `/authlink` 登录回流 + `/event/learn-from-home`/`/event/plus25`
  营销事件页：登录/Learn 边界（ADR-0662/0652）；App Links
  autoVerify 为 Play 验证机制。

## 后果

AndroidManifest 审计至属性级全闭。代码零变更。
