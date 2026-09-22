# ADR-0559：选区常态 pointer-down —— 内部拖拽整体 / 外部 TapToSelect / ClearSelection

- 状态：accepted（**取代并纠正 ADR-0558**）
- Phase：590
- 证据：`docs/migration/evidence/original-selection-tap-clear-2026-09-28.md`

## 背景

ADR-0558（Phase 589）把 `ftc.i` 误读为"moving set"，据此实现了
"按下命中哪个选中元素就只拖哪个"的元素粒度抓取。深入核对 `ftc.java`
toString 与 `dhb.java:18035` 后确认：`ftc.h` = **deselectMode**、
`ftc.i` = **deselectedIds**——`stc`/`ej9 case18` 是 deselect 菜单模式下
的**点按移出选区**语义，不是抓取移动。

原版常态（`h=false`）的真实契约（`dl1.java` case2 else 分支）：

- 覆盖层内按下 → `wtc` → `e39`：**拖拽整个选区**；
- 覆盖层外按下命中元素 → `vtc` → `uw2 case3`：**TapToSelect**（元素命中
  → 选该元素；`cqc` 组命中 → `gtc` 组选择态）；
- 覆盖层外未命中 → `rtc` → `ct0`：**ClearSelection**；
- deselectMode（菜单 `dhb` case20 置位）→ `stc` 点按移除。

## 决定

纠正 Phase 589：

1. 恢复"选区内按下 → 整体拖拽"（`pointInRect(selectionRect)` →
   `selectionDrag`）。
2. 选区外按下：
   - `topmostPageElementIdAt`（统一 z 序逆序逐类命中：笔画/形状精确覆盖，
     TEXT/IMAGE/MATH 逆仿射局部矩形）命中 →
     `resolveOriginalGroupSelection` 组展开 → `selectElementIds`（TapToSelect）；
   - 未命中 → `clearSelectionWithRegisterReset()`（ClearSelection）。
3. 移除 `movingIds`/`grabElements`/`movingSubsetOf` 及其收窄逻辑——
   它实现的是 deselectMode 语义，而 Harmony 选区菜单无该模式入口，
   保留即成死代码。deselectMode 若日后增加菜单项再按 `ej9(18)` 移植。
4. `!selectionVisible` 时按下仍走套索/矩形新手势（与原版非选中态一致）。

## 有界偏差

- 旋转选区：原版 `yxi.e(cmb)` 旋转感知，Harmony 用 AABB——AABB 内、
  旋转矩形外的边角按下在原版走 vtc/rtc、在 Harmony 走拖拽。
- `gtc` 组选择态内按成员 → `ttc → uw2 case4` 元素级菜单（`qke`）未映射；
  Harmony 组选择内按下按 `wtc` 整体拖拽。
- deselectMode 整体未移植（无菜单入口）。

## 验证

- Replay：`d02-original-selection-tap-clear.mjs`（18 项契约，含
  Phase 589 机制已移除的反向断言）。
- `note@default` / `note@ohosTest` 构建通过。
