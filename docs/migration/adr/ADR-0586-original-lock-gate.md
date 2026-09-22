# ADR-0586 — LOCK/UNLOCK 门槛（xsc.k 成员解析 + dhb case18/19）

- 状态：Accepted
- Phase 617；对齐 `xsc.k`（decompiled_1.0.3:216-240）与
  `dhb` case18/19（17997-18034）。

## 背景

原版 LOCK/UNLOCK 的可用性按选区壳类型分流：

- `itc` 单元素：`u5j.n`（`oy0` 块）/`u5j.x`（`m4d` 形状）
  翻转 `t()`；`s06` 笔画 → `objX` 空 → 死操作。
- 非 itc：`xsc.k` 解析 `ktc.h()` 平铺成员——任一成员非
  `m4d`（笔画/oy0 块）→ null 死路径；须存在 `cih.a`
  （`n5d` 形状）成员；方向 = 全部 n5d 已锁 → UNLOCK。
  执行端按 `t() != z15` 逐项过滤。

元素类型层级：`n5d`(形状) 是唯一 `m4d`；`hp5`(图像)/
`r08`(文本/数学) 为 `oy0`；笔画 `s06`。

Harmony 旧门槛 `onlyShapesSelected || selectedCount === 1`：

- `selectedCount` 含笔画 → **单笔画选区显示 LOCK**（原版死）。
- 单元素未区分笔画/块——原版 itc 对 s06 死、对 oy0/m4d 活。

## 决策

1. `selectionCanLock = allMembersAreShapes ||
   (无组 && selectedCount === 1 && lockableCount === 1)`：
   - `allMembersAreShapes`：展开选中组叶子后，平铺成员集
     （散件 id + 组叶子）全部落在形状 id 集——`xsc.k` 的
     「全 m4d 且有 n5d」等价判定（唯一 m4d 元素=形状）。
   - 单元素须 `lockableCount === 1`（形状/文本/图像/数学），
     单笔画（`lockableCount === 0`）死路径对齐。
2. `selectionPositionLocked` 增加「组成员形状全锁」判定——
   方向对选中形状组同样正确（全部成员锁 → UNLOCK）。
3. `setSelectedPositionLocked` 把组叶子并入生效形状 id 集，
   保留 `positionLocked === locked` 逐项跳过（=`t() != z15`
   过滤）。

## 边界

- 组叶解析失败（`null`）→ `allMembersAreShapes` 为假，
  仅单元素路径可放行——fail-closed。
- {形状+图像}/{形状+笔画}/纯图像组 → 均非全形状 → 死，
  与 `xsc.k` null 一致。
- 单图像/单文本/单数学块 → `lockableCount === 1` → 可锁，
  对应 itc 的 `u5j.n(oy0)` 路径。
