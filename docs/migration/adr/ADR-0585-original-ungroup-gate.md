# ADR-0585 — UNGROUP 仅 gtc 单组选区可触发（dhb case5）

- 状态：Accepted
- Phase 616；对齐 `dhb` case5（decompiled_1.0.3:17655-17672）。

## 背景

原版 UNGROUP（`dsc`=5）在 `dhb` case5 中只对 `gtc`——
整个选区恰为单个组——派发 `wsc` 解组协程。`ftc` 多选壳
分支虽解析出 `ftc.m` 首组成员集 `listN0`，但随后直接
`return mof.a`，不派发协程：**混选含单组时 UNGROUP 是死
操作**；`itc`/`etc` 落到不可达分支同样不执行。

Harmony 旧实现：`selectionCanUngroup =
selectedGroupIds.length === 1 && 组存在 && 叶子可解析`——
混选 {一个组 + 散件} 满足条件，菜单显示且 `ungroupSelectedElements`
照常执行，与原版分叉。

## 决策

1. `selectionCanUngroup` 改为「顶层项恰为 [组id]」：
   `resolveOriginalGroupAuthoringMembers(...) !== null &&
   length === 1 && members[0] === selectedGroupIds[0]`。
   `groupMembers` = `ftc.q` 未入组散件 + 组 id 等价集——
   长度 1 且为组 id ⇔ `gtc`。
2. `ungroupSelectedElements` 入口同门槛 fail-closed——
   对应原版 `ftc` 分支的静默返回。
3. 保留既有 `findSelectionGroup`/`resolveOriginalSelectedGroupLeaves`
   检查（对应 `l0(gtc.a)` 非空才派发 `wsc`）。

## 边界

- 单组选区：行为不变——组存在且成员可解析即可解组，
  解组后 `fvb.a()` 清选区语义已由粘贴/解组路径覆盖。
- 混选含单组：菜单隐藏 + 执行端拒绝，与原版死路径一致。
- 组图损坏（`groupMembers === null`）→ 门槛为假，fail-closed。
