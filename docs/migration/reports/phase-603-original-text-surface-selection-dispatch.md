# Phase 603 — TEXT 面选区手势分发 + 裸笔压制（dl1 z / elh.h）

- 日期：2026-09-23
- 结果：已实现对齐（一处 JADX 伪影按 fail-closed 裁决）
- 证据：`docs/migration/evidence/original-text-surface-selection-dispatch-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0572-original-text-surface-selection-dispatch.md`
- Replay：`d02-original-text-surface-selection-dispatch.mjs`（15 项断言）

## 背景

`dl1` case2 为共享选区手势分发器；TEXT 面（`m5f`/`a6f.L`）以
`z=true` 挂接 → `z3 = !(z && !elh.h)`，裸笔（非手指、无桶键）
外按的 `rtc`/`vtc` 产出被压制为 `utc`，手势落回文本面；
覆盖层内 `wtc`/`ttc`/柄与 deselectMode 分发不经门。

Harmony 的 DEFAULT（TEXT 面对应）分支此前完全忽略选区：
手指外按不清选、命中不选、覆盖层内不可拖。

## 实现

- DEFAULT pointer-down 在 tape/checkbox 后插入 dl1 分发：
  菜单排除 → deselectMode（不门）→ 覆盖层内（柄/ttc/wtc，不门）
  → 外按 `!stylusSuppress`（`SourceTool.Pen`≈裸笔）产 vtc/rtc
  → 落空交还文本手势面。
- 抽取共享助手 `applyTapSelect`/`beginSelectionDragSession`/
  `tryStartSelectionResize`/`insideOverlayElementTap`，SELECTION
  面同步改调用，净去重。

## 偏差

- gtc 外按臂 JADX 反转 → 采用 ftc 语义（fail-closed，见 ADR）。
- 桶键不可得 → 笔恒按裸笔压制处理。

## 验证

- 专项 15/15；`note@default` 构建 0 错误。
