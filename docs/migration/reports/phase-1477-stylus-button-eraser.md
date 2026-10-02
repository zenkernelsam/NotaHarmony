# Phase 1477 报告 — 手写笔杆键擦除切换 → fail-closed

## 原版行为（decompiled_1.4.2）

`bd8.B()`（`f2.java:148` 第一遍分发器）尾支
（`bd8.java:208-215`）：

- **笔杆四键**：`k0` = `ofk.e(308..311)` =
  Android `KEYCODE_STYLUS_BUTTON_PRIMARY/SECONDARY/TERTIARY/TAIL`；
- 门控：无任何修饰键 + `G()` = 特性旗
  `h35.q0` = **"STYLUS_BUTTON_ERASER_TOGGLE"**（td5 日期门
  2026-09-03 起）；命中即消费；
- KeyUp → `D()`：`o5h` 防抖机（`e`=100ms 窗）——
  - `c`=true（笔键擦除激活中）→ `c=false` + `d=now`（解除）；
  - `d` 100ms 内重按 → 抑制；
  - `b` 为空或 ≥100ms → `b=now` + `hxi.a.f(fxi.a)` 发
    **ToggleEraser**；
- `npb.java:53-72`：`fxi` → `f6n.e(vti)` 擦除工具 id → 工具
  列表按 id 找 `wsi` → `xqb.B(wsi)` **选中擦除工具**。

## Harmony 结论：fail-closed

- OpenHarmony `keyCode.d.ts` 全枚举无 `KEYCODE_STYLUS_*`——
  笔杆键不进 `KeyEvent`；
- `touchEvent.d.ts` `ToolType.PEN`/`SourceType.STYLUS` 无
  button 字段；
- `ArkUIStylusAdapter.ets` 无按键路径。

按项目规则（系统能力缺失/Android-only → fail-closed）不移植、
不写假实现。若未来 Harmony 暴露笔键事件，落点 =
`viewModel.selectTool(ERASER)` + `o5h` 100ms 防抖（ADR-1412）。

## 验证

- `d02-original-stylus-button-eraser.mjs`：**9 checks OK**
  （钉死当前无笔键码处理路径 + SDK 枚举缺席 + o5h 防抖
  可执行模型 5 例）；
- 无源码改动 → 无需构建验证；全量基线照常跑。

## 文件

- `docs/migration/replays/d02-original-stylus-button-eraser.mjs`
- `docs/migration/evidence/phase-1477-stylus-button-eraser.md`
- `docs/migration/adr/ADR-1412-stylus-button-fail-closed.md`
