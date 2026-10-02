# ADR-1412：手写笔杆键擦除切换 fail-closed（无 Harmony 通道）

## 状态

已接受（Phase 1477）——**fail-closed / Android-only**。

## 背景

原版 `bd8.java:208-215`（`B()` 第一遍分发器尾支）：
`k0` = Android `KEYCODE_STYLUS_BUTTON_PRIMARY..TAIL`（308-311）
+ 无修饰键 + `G()`=STYLUS_BUTTON_ERASER_TOGGLE 特性旗 →
KeyUp `D()`：`o5h` 100ms 防抖 → `hxi` 通道发 `fxi`
（ToggleEraser）→ `npb` 按 `f6n.e` 擦除工具 id
`xqb.B(wsi)` 选中擦除工具。

## 决策

**不移植**。Harmony/OpenHarmony 公共 SDK 无笔杆键通道：

- `keyCode.d.ts` 全枚举无 `KEYCODE_STYLUS_*`；
- `touchEvent.d.ts` `ToolType.PEN`/`SourceType.STYLUS` 无 button
  字段；
- 无系统手势策略兜底可枚举。

按项目规则（Android-only / 系统能力缺失 → fail-closed），
不写假实现、不猜键码。

## 后果

- 用户不能用笔杆键切擦除——差异登记入修复总纲；
- 未来 Harmony 若新增笔键事件（KeyEvent/TouchEvent button 字段），
  落点已知：`xqb.B(擦除 wsi)` 语义 ≈ Harmony
  `viewModel.selectTool(ERASER)` + `o5h` 100ms 按下/解除防抖；
- fixture `d02-original-stylus-button-eraser.mjs` 钉死当前无
  处理路径的状态（防误加半成品）。
