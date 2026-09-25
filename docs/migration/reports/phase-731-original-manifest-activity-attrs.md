# Phase 731 中文报告：MainActivity 属性级审计收口

## 范围

`MainActivity` 元素属性 + 5 条 intent-filter 逐项核对（manifest
审计最后一段，文档级）。

## 原版证据

见 `docs/migration/evidence/original-manifest-activity-attrs-jadx-2026-09-25.md`。

- `windowSoftInputMode=adjustNothing`：编辑器依赖 Compose
  `WindowInsets.ime` 自管 inset。
- `showWhenLocked`/`turnScreenOn`+`LAUNCH_CAPTURE_CONTENT_ACTIVITY_
  FOR_NOTE`：Samsung 锁屏速写链路。
- `singleInstancePerTask`：多 task 多文档窗口。
- autoVerify App Links：`notability.com`/`*.notability.com` 的
  `/app/note`、`/authlink`、`/event/learn-from-home`、`/event/plus25`。

## 归属结论

- 语义等价：exported/configChanges/resizeableActivity、
  `/app/note` 深链（DeepLinkIngress+resolveDeepLinkNoteId 在位）。
- 登记差异：adjustNothing→系统 OFFSET 避让（全局 NONE 会令非编辑器
  页输入被键盘覆盖，原版自管 inset 链路不存在于 Harmony 侧）；
  singleInstancePerTask→singleton+onNewWant 单窗口路由；
  sendMultipleData 为增强覆盖。
- 边界：锁屏速写三件套（Samsung/系统特权）、/authlink、/event/*
  （登录/Learn 域）。

## 验证

- `d02-original-manifest-activity-attrs.mjs` 专项全绿。
- 全量 Desktop Replay 全绿；双 HAP clean（文档级阶段）。
- AndroidManifest 审计至属性级全闭。
