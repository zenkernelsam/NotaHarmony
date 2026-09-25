# ADR-0657 「SPen Quick Tools」三星手写笔快捷工具 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：709
- 接续：ADR-0656（外部运行时 fail-closed 判据）、ADR-0626
- 证据：`docs/migration/evidence/original-spen-quick-tools-jadx-2026-09-25.md`

## 背景

原版 `ac4.T`（`SPEN_QUICK_TOOLS`，序号 8）控制三星手写笔
"快捷工具"悬浮面：

- `xod.a()`：`te3.a()`（`Build.MANUFACTURER` 含 "samsung"/
  "samsung electronics"，`ra` case23）**且** `lc4.a(ac4.T)`
  → `ufb` 可用性流；
- `bq1`（TOOLBAR case5）：手写笔悬停/工具位事件到来时，若
  `xod.b` 为真 **且** `w7b.b()` 已配对笔列表包含 `r5fVar.g()`
  **且** `e31`（笔远程事件源）非空 → 发射 `u7b(x, y, stylusId,
  e31VarA.c, w7b.a(quickToolItems, stylusId))`——快捷工具
  弹出状态（笔/铅笔/荧光笔/橡皮/颜色，`feature_note__cd_
  quick_tool_*` 无障碍串在案）。

## 决定

1. **不实现 SPen Quick Tools**，登记结构性 fail-closed：该面
   同时依赖 (a) 三星厂商设备、(b) SPen 远程 SDK（`e31`/`r5f`
   蓝牙笔按键/悬空事件协议）、(c) 远程旗标——Harmony 手写笔
   栈（Pencil Kit）无对应远程事件协议，且厂商门在 Harmony
   设备上恒为假。
2. **Harmony 呈现旗标关闭态**：无快捷工具弹出、无笔按键
   监听——与原版在非三星设备/旗标关闭时完全一致。
3. `cd_quick_tool_*` 无障碍串中仅 `cd_quick_tool_color` 被
   复用（色板按钮描述，ADR-0529 已登记）——与快捷工具面无
   关联，不属于本边界。

## 后果

- 非三星设备/旗标关闭的原版体验 = Harmony 体验；
- 若 Harmony Pencil Kit 未来提供等价悬空/按键事件流，可重审
  本 ADR。
