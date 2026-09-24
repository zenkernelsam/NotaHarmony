# Phase 663 证据：原版桌面快捷方式（v50 → CREATE_NOTE + start_camera）

日期：2026-09-24
关联：ADR-0630；前置 Phase 661（共享入口 want 队列模式）、
Phase 657/662（编辑器拍摄/导入入口）

## 原版实现（decompiled_1.0.3）

### v50 —— ShortcutManager 动态快捷方式发布器

`defpackage/v50.java`（`v50.a(v50, mc7)`）：

- `dad.b = "new_note"`：标签 `app__shortcut_new_note`，图标
  `app__shortcut_new_note`，intent =
  `new Intent().setClassName(pkg, MainActivity)
   .setAction("android.intent.action.CREATE_NOTE")`。
- `dad.b = "new_photo"`（`pceVar` 布尔门控）：同上 +
  `putExtra("start_camera", true)`。
- 近期笔记动态快捷项：`fad.P(mc7Var.d.values(), 上限-已占名额, 0, 2)`
  由最近笔记驱动，`fad.R(context, ...)` →
  `ShortcutManager.setDynamicShortcuts` 发布。

### hv7.i —— 启动标记

`defpackage/hv7.java:58`：

```java
if (ba6.o(intent.getAction(), "android.intent.action.CREATE_NOTE")
    || fag.h0(intent) != null
    || (data != null && py2.d(data))) {
    this.Q.j = true;
}
xj2.A(h(), null, null, new kx(10, null, intent, this), 3);
```

CREATE_NOTE 与普通冷启动走同一 `kx` 协程管线：建笔记 → 打开编辑器
（new_photo 的 start_camera extra 驱动编辑器直起拍摄）。

## Harmony 对齐实现

### 声明

- `module.json5` → `NoteAbility.metadata`：
  `ohos.ability.shortcuts` → `$profile:shortcuts_config`。
- `resources/base/profile/shortcuts_config.json`：两条静态快捷项
  `new_note`/`new_photo`，label/icon 资源 +
  `wants[].parameters.launch_action`（`create_note` /
  `create_photo_note`）。
- 图标：`media/shortcut_new_note.svg`、`shortcut_new_photo.svg`
  （按原版 adaptive-icon 语义重绘为单色矢量）。

### 入口队列

- `data/LaunchActionIngress.ets`：`enqueueLaunchAction(want)` 读
  `want.parameters['launch_action']`（白名单两值）；
  `drainLaunchActions()` 原子清空。与 SharedFileIngress 同模式：
  want 早于 UI 到达，队列保证不丢。
- `NoteAbility.onCreate`/`onNewWant` 均调用。

### 消费

- `LibraryPage.onPageShow` → `drainLaunchIngress`：
  `create_photo_note` → `createAndLaunch(false, undefined, true)`；
  其余 → `createAndLaunch(false, undefined, false)` —— 与内建「+」
  同一建笔记管线（含 `createBusy`/`lifecycleGeneration` 守卫）。
- `createAndLaunch` 第三参 `startCamera` → pushUrl
  `params.startCamera='1'`。
- `NotePage`：`startCamera` param → `autoCameraRequested` → 笔记载入
  完成后（`pageLoadGeneration` + `editorDisposed` 守卫，同 autoRecord
  挂点）`photoImportLeaseActive = true; cameraCaptureSignal++` ——
  与 Take Photo 同一 ingress lease 直起拍摄。

## 已登记差异 / fail-closed

1. **近期笔记动态快捷项**：原版 `ShortcutManager.setDynamicShortcuts`
   由最近笔记驱动；Harmony `ohos.ability.shortcuts` 仅支持静态声明，
   无动态快捷方式 API —— fail-closed 登记（`LaunchActionIngress`
   注释），近期笔记入口由库页本身承担。
2. **new_photo 门控**：原版 `pceVar` 布尔门控（相机可用性/权限配置）
   决定是否发布；Harmony 无条件声明两项 —— 拍摄权限在起摄时按既有
   photo ingress 流程处理。
3. **多动作连发**：每次快捷方式点击 = 一个 want = 一个建笔记动作；
   drain 逐条处理，语义与原版逐 intent 一致。

## 验证

- `docs/migration/replays/d05-original-launcher-shortcuts.mjs`：
  26 断言全绿（v50/hv7 证据 + 声明 + 队列 + drain + startCamera +
  字符串 + fail-closed 登记）。
