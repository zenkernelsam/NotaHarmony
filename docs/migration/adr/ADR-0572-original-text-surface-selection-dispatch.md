# ADR-0572 — TEXT 面选区手势分发 + 裸笔压制（dl1 z / elh.h）

- 状态：Accepted（含一处 fail-closed 反编译伪影裁决）
- Phase 603；对齐 `dl1`/`nti`/`elh`（decompiled_1.0.3）。

## 背景

`dl1` case2 是挂在多个工具面上的共享选区手势分发器。`nti`
两个 `rz1.C` 挂点给出表面标志：手写面 `z=false,z2=true`，
TEXT 面（`m5f`/`a6f.L`）`z=true,z2=false`。`z3 = !(z && !elh.h)`，
`elh.h` = 手指触摸或手写笔桶键 → **裸笔在 TEXT 面上的
`rtc`/`vtc` 产出被压制为 `utc`**，手势落回文本面；覆盖层内
`wtc`/`ttc`/柄与 deselectMode 分发不经门。

Harmony 的 DEFAULT（TEXT 面对应）分支此前完全忽略选区状态：
手指外按不清选、元素命中不选中、覆盖层内不可拖——与原版不符。

## 决策

1. `ToolType.DEFAULT` pointer-down 在 tape/checkbox 后、双击编辑
   前插入 dl1 分发块：菜单区域排除 → deselectMode（不门）→
   覆盖层内（`tryStartSelectionResize`/`insideOverlayElementTap`/
   `beginSelectionDragSession`，不门）→ 外按 `!stylusSuppress`
   （`SourceTool.Pen`≈裸笔）才产 `applyTapSelect`(vtc) /
   `clearSelectionWithRegisterReset`(rtc) → 落空交还文本面。
2. 抽取共享助手 `applyTapSelect`/`beginSelectionDragSession`/
   `tryStartSelectionResize`/`insideOverlayElementTap`，
   SELECTION 面既有分支同步改调用，避免三份拷贝漂移。

## 偏差（fail-closed 记录）

1. **gtc 外按臂反编译反转**：`dl1` 字面为 gtc 态 `z3→utc、
   !z3→rtc/vtc`（与 ftc 相反）。字面执行使纯组选区在手写/SELECT
   面永远无法外按清除（z=false→z3 恒真），判定为 JADX 臂交换
   伪影；Harmony 对所有覆盖层态采用 ftc 语义（z3→rtc/vtc）。
   若后续真机/其他版本证据表明组选区外按确有差异再回改。
2. **桶键不可得**：`elh.h` 的手写笔桶键（button 66）在 Harmony
   TouchEvent 无对应面；一律按裸笔处理（TEXT 面笔输入恒压制），
   与"无桶键"情形等价。
3. **gtc 成员 ttc 死臂**：成员命中 ttc 臂位于 `ftc` 块内要求
   `gtc` 的不可达分支，判定为 JADX 跨块错置、语义属 gtc；
   Phase 593 移植保留，本 Phase 以共享助手维持。
4. 覆盖层"inside"判定 Harmony 用 `selectionRect`+柄命中近似
   `yxi.e`（含柄区），偏差已在上批角柄 ADR 记录。

## 验证

- `docs/migration/replays/d02-original-text-surface-selection-dispatch.mjs`
  15 项断言（门序/不门路径/共享助手复用）。
- 证据：`docs/migration/evidence/original-text-surface-selection-dispatch-2026-09-23.md`。
