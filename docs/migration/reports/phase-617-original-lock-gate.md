# Phase 617 — LOCK/UNLOCK 门槛（xsc.k 成员解析 + dhb case18/19）

## 原版证据

- 类型层级：`n5d`(形状) 是唯一 `m4d`（`n5d.java:8`）；
  `hp5`(图像)/`r08`(文本/数学) 是 `oy0` 非 `m4d`；笔画 `s06`。
- `xsc.java:216-240` `k(ktc)`：解析 `ktc.h()` 平铺成员，
  任一成员非 `m4d` → null 死路径；须存在 `n5d` 成员；
  返回 `z2` = 全部形状已锁 → UNLOCK 方向。
- `dhb.java:17997-18034` case18/19：`itc` 单元素 `u5j.n`(oy0)/
  `u5j.x`(m4d) 翻转 `t()`，`s06` 笔画产出空 op；非 itc 按
  `xsc.k` 判向 + `t() != z15` 过滤 → `vz6` + 清选区。

## 排查结论

Harmony 旧门槛 `onlyShapesSelected || selectedCount === 1`：
`selectedCount` 计入笔画——**单笔画选区显示 LOCK**（原版
itc 对 `s06` 产出空 op，死操作）；且多选/单组未按
`ktc.h()` 成员展开语义声明门槛。

## 修复

- `updateSelectionOverlay`：`allMembersAreShapes` =
  散件 id + 组叶子全部 ∈ 形状 id 集（`xsc.k` 全 m4d 等价）；
  `selectionCanLock = allMembersAreShapes || (无组 &&
  selectedCount === 1 && lockableCount === 1)`——单笔画
  不再可锁。
- `selectionPositionLocked`：增加组成员形状全锁判定，
  选中形状组的 LOCK/UNLOCK 方向正确。
- `setSelectedPositionLocked`：组叶子并入生效形状集合；
  `t() != z15` 逐项过滤保留。

## 验证

- 新增 replay `d02-original-lock-gate.mjs`：12/12 绿；
  更新 `d02-local-position-lock.mjs` 至新门槛形态。
- 全量 desktop replay 套件：507/507 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。
- 未启动模拟器/真机/Hypium。

## 提交

`Phase 617: LOCK gate follows xsc.k member resolution (all-shapes or single non-stroke)`
