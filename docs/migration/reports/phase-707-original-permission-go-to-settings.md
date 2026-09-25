# Phase 707：原版权限拒绝对话框「Go to Settings」移植

`ui_permissions__*` 扫描发现：原版权限拒绝对话框（`e32` case0/1）
为双按钮——`go_to_settings`（首按钮，打开系统权限设置页）+
`dismiss`（次按钮）。Harmony 的麦克风 `PERMISSION_DENIED` 对话框
只有单个 Dismiss。

## 实现

- `NotePage.ets` `showRecordingFailure` PERMISSION_DENIED 分支：
  双按钮 `[Go to Settings, Dismiss]`（原版序）；
  `response.index === 0` + `editorDisposed` 守卫 →
  `abilityAccessCtrl.createAtManager().requestPermissionOnSetting(
  context, ['ohos.permission.MICROPHONE'])`——系统级权限设置页
  深链（SDK `requestPermissionOnSetting` 已存在）。
- 新字符串 `go_to_settings`："Go to Settings"（base）/
  "前往设置"（zh_CN）；`abilityAccessCtrl` 并入既有
  `@kit.AbilityKit` import。

## 原版差异登记

- 原版对话框含 camera/microphone 两变体；Harmony 相机走系统
  `cameraPicker`（无需权限），仅麦克风触达此对话框——与原版
  相机无权限路径一致。

## 验证

- `d02-original-permission-go-to-settings.mjs`（9 断言：原版串/
  e32 序/双按钮/requestPermissionOnSetting/守卫/import/双 locale）。
- 全套件重跑通过后记录于修复总纲；双 HAP 0 错误。
