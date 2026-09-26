# ADR-0771 — 输入面差异登记：键盘和弦 / 摇一摇 / 动态快捷方式

## 状态

已接受（缺口登记；编辑器级按键已对齐，活动级和弦暂缓移植）。

## 背景

原版 `MainActivity` 承载三类输入面：

1. **硬件键盘和弦面**：`dispatchKeyEvent` 活动级调度 + 三个注册表
   （`syh` 文本编辑 17+ 和弦、`cma` 导航组、`f3b` 组）+ 系统快捷键
   帮助清单（`txm`→`KeyboardShortcutInfo`，7 个 `app__kbd_shortcut`
   文案键）。和弦语义完整恢复：Ctrl+C/V/X/A/Z/Y、Ctrl+Shift+Z、
   Ctrl+B/I/U、Ctrl+Shift+B/N/C、Ctrl+Alt+↑↓ 字号、Ctrl+Alt+Shift+↑↓
   首尾、Esc 取消选择。
2. **摇一摇手势**：加速度计 ≥2.7g + 1s 去抖 → 应用动作
   （`MainActivity.l().d()`），onResume/onPause 注册注销。
3. **快捷方式**：manifest 无静态 shortcuts 声明，代码中亦仅有
   `ShortcutManagerCompat` vendor 实现——原版无应用级快捷方式面，
   launcher 项来自系统自动暴露。

## 决定

1. **文本编辑和弦已等价**：Harmony `TextBlockOverlay.onEditorKeyEvent`
   实现 Ctrl+B/I/U/A/D/Home/End 等——与原版 `syh` 注册表同域。
2. **活动级和弦面登记缺口**：新建笔记/新窗口/回库/帮助/设置和弦
   无 Harmony 对应——ArkUI `.onKeyEvent` 冒泡模型可实现但需实机
   验证按键码映射，暂缓移植并登记。
3. **摇一摇 fail-closed 登记**：Harmony 无传感器调用；手势语义
   （`l().d()`）为 debug/快捷路径，非核心功能，不补。
4. **快捷方式为 Harmony 主动补齐**：`shortcuts_config.json` 静态
   双项（new_note/new_photo）是 Harmony 新增，非原版面缺失。

## 后果

- 输入面闭合：键盘和弦表完整解码登记；摇一摇与动态快捷方式
  归 fail-closed/差异档。
- 新增 `d02-input-surfaces.mjs` 回归：调度器/摇一摇参数/和弦表
  完整性/Harmony 现状核验。

## 已验证

- `d02-input-surfaces.mjs`：24/24。
- 全量 Desktop Replay + 双 HAP 构建（随 Phase 827 提交）。
