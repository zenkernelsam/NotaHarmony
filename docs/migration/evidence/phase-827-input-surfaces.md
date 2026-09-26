# Phase 827 — 输入面审计：硬件键盘快捷键 + 摇一摇手势

证据来源：`decompiled_1.4.2` `MainActivity.dispatchKeyEvent`/
`onProvideKeyboardShortcuts`、`d4g.java`（传感器监听器）、
`res/values/strings.xml` `app__kbd_shortcut_*`；Harmony `ets/` 全量扫描。

## 一、硬件键盘快捷键面

### 原版

`MainActivity.dispatchKeyEvent`（675 行）实现活动级按键调度：

- `qdn.a(keyEvent)` / `vla.a/b(keyEvent)`：和弦匹配器，解析为
  `ama` 动作枚举，经 `bma.a.f(ama)` 派发——应用级快捷键表。
- 命中 "New Window chord" 时校验 `oim.a(configuration)`（多窗能力），
  不可用时记录 `New Window chord dropped: launcher not ready` 日志。
- `onProvideKeyboardShortcuts` 经 `txm.a(resources)` 注入
  `app__kbd_shortcut_*` 帮助清单（系统快捷键帮助弹层内容）。

字符串清单（7 键，1.0.3=1.4.2 零差）：
`group_navigation`（分组头）、`back_to_library`、`new_note`、
`new_window`、`open_help`、`open_settings`、`dismiss_deselect`。

### Harmony 现状

`TextBlockOverlay.onEditorKeyEvent` 实现**编辑器内**文本快捷键：
Ctrl+B/I/U、Ctrl+A、Home/End、Ctrl+D 去选等 6+ 键位——
文本编辑域快捷键已移植；但**应用级和弦面**（新建笔记/新窗口/
回库/帮助/设置）无对应处理——平板生产力手势缺口。

## 二、摇一摇手势

`d4g implements SensorEventListener`：加速度计（TYPE_ACCELEROMETER）
幅值 `|v|/9.80665 ≥ 2.7g` 且 ≥1s 去抖 → 触发 `MainActivity.l().d()`
（窗口有焦点时）。`MainActivity` 在 `onResume`/`onPause` 注册/注销
（SENSOR_DELAY_GAME）。语义为摇一摇触发应用动作（调试或快速操作）。

Harmony `ets/` 无 sensor/accelerometer 使用——该手势未移植。

## 三、快捷方式面补充更正

复检后确认 `oag.java` 即 AndroidX `ShortcutManagerCompat` 本体
（vendor 兼容层，非应用推送者）；manifest 亦无静态 shortcuts 声明——
**原版无应用级动态快捷方式面**，launcher 快捷项来自系统对
share/capture activity 的自动暴露。Harmony `shortcuts_config.json`
静态双项（new_note/new_photo）为主动补齐，登记为 Harmony 新增。

## 四、结论

输入面审计结果：
- 应用级键盘和弦面（6 快捷键 + 帮助清单）为未移植缺口——
  Harmony 已有编辑器级按键处理，缺活动级和弦调度。
- 摇一摇手势（2.7g/1s 防抖加速度计）无 Harmony 对应。
- 动态快捷方式面与静态 `shortcuts_config` 存在形态差异。
