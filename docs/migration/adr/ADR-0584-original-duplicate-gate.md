# ADR-0584 — DUPLICATE 顶层项 >=2 门槛（dhb case4）

- 状态：Accepted
- Phase 615；对齐 `dhb` case4（decompiled_1.0.3:17638-17654）。

## 背景

原版 DUPLICATE 菜单动作仅在 `ktcVar instanceof ftc` 且
`A1 = T1(ftc.q) + 组 id` 集合 `size() >= 2` 时执行——`ftc` 是
多选壳（`itc` 单元素、`gtc` 单组根本不进 case4），`ftc.q`
不含组成员（`gtc.f()=qw3` 空集），故门槛语义是「顶层项
（散件+组）≥2」。不满足时整个 case 静默返回，无副作用。

Harmony 旧实现：`SelectionOverlay` 无条件 push DUPLICATE，
`duplicateSelected` 亦无门槛——单元素、单组都能复制，
与原版用户可见行为分叉。

## 决策

1. `selectionCanDuplicate` 状态 =
   `resolveOriginalGroupAuthoringMembers(...) !== null &&
   members.length >= 2`。该函数正是 `T1(ftc.q)+组 id` 等价集：
   散件剔除选中组叶子成员后 + 选中组 id——与既有 GROUP 门槛
   共用同一份计算（`updateSelectionOverlay` 内 `groupMembers`）。
2. `SelectionOverlay` 增 `@Prop canDuplicate`，DUPLICATE 项
   条件 push，菜单顺序不变。
3. `duplicateSelected` 入口同门槛 fail-closed——对应原版
   `ftcVar == null`/`<2` 的静默路径，双保险。
4. 不附加 `allCanonicalOperationIds`（那是 GROUP 的额外条件；
   `dhb` case4 无此要求）。

## 边界

- `groupMembers === null`（组图损坏）→ 门槛为假，菜单隐藏且
  兜底拒执行——fail-closed 与原版静默语义一致。
- 单组（含任意多成员）= 1 顶层项 → 不可复制，与 `gtc` 不进
  case4 一致。
- DUPLICATE 仍走内部剪贴板+粘贴的已登记适配（原 `kk9` 协程
  专用 op 未反编译），本次只对齐触发门槛。

## 验证

- 桌面 replay：`docs/migration/replays/d02-original-duplicate-gate.mjs`，12/12。
- `note@default`/`note@ohosTest` 构建绿；全量 replay 套件绿。
