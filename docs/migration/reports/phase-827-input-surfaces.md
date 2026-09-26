# Phase 827 — 输入面审计：键盘和弦 / 摇一摇 / 快捷方式

## 范围

原版活动级输入面（硬件键盘和弦、加速度计手势、动态快捷方式）
挖掘与 Harmony 现状核验。

## 原版证据

### 硬件键盘和弦（`MainActivity.dispatchKeyEvent`）

- `qdn.a`/`vla.b` 和弦解析 → `ama` 动作枚举派发；`onProvideKeyboardShortcuts`
  经 `txm.a` 输出系统帮助清单。
- 和弦表完整解码（`qa8(keyCode, metaMask)` + `KeyboardShortcutInfo` 构造，
  meta 位：ctrl=4096/alt=2/shift=1）：
  - 文本编辑组（`syh`）：Ctrl+C/V/X/A/Z/Y、Ctrl+Shift+Z、Ctrl+B/I/U、
    Ctrl+Shift+B（无序）/N（有序）/C（清单）、Ctrl+Alt+↑↓（字号）、
    Ctrl+Alt+Shift+↑↓（首/尾）、Esc 去选。
  - 导航组（`cma`）：`back_to_library`/`new_note`/`new_window`/`open_help`/
    `open_settings` 五条 + dismiss_deselect（Esc）+ New Window 和弦带
    多窗能力校验（`oim.a(configuration)`）。
- 7 个 `app__kbd_shortcut_*` 帮助文案键，1.0.3=1.4.2 零差。

### 摇一摇

`d4g` SensorEventListener：`|a|/g ≥ 2.7` 且 1s 去抖 → `l().d()`。
onResume 注册（SENSOR_DELAY_GAME）/onPause 注销。

### 快捷方式（更正）

`oag` 实为 AndroidX `ShortcutManagerCompat` vendor 类本体；manifest
无静态 shortcuts 声明——原版**无应用级动态快捷方式面**，launcher
快捷项来自 share/capture activity 的系统自动暴露。Harmony 静态
`shortcuts_config`（new_note/new_photo）为主动补齐。

## Harmony 核验

- `TextBlockOverlay.onEditorKeyEvent`：编辑器级快捷键存在（B/I/U/A/D/
  Home/End）——文本编辑域与原版对齐。
- 活动级和弦（new_note/new_window/library/help/settings）未移植——缺口登记。
- 无 sensor/加速度计调用——摇一摇 fail-closed。
- 静态 `shortcuts_config.json`（new_note/new_photo）已覆盖主入口。

## 交付物

- 证据：`docs/migration/evidence/phase-827-input-surfaces.md`
- ADR：`docs/migration/adr/ADR-0771-input-surfaces.md`
- Replay：`docs/migration/replays/d02-input-surfaces.mjs`（24 项断言）

## 验证

- 新增 Replay：24/24。
- 全量 Desktop Replay、双 HAP 构建随本 Phase 完成。

## 下一步

输入面闭合。剩余候选：baseline.prof（二进制无法静态采样）、
`assets/binData` 残留、或 Harmony 侧死代码反向审计。
