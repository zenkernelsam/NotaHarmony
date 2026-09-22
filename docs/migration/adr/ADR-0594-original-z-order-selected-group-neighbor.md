# ADR-0594: z-order 一步移动中选中组不阻挡交换（zh9/py case26 语义）

- 状态：已接受
- 日期：2026-09-28；Phase 625
- 证据：`docs/migration/evidence/original-z-order-selected-group-neighbor-2026-09-28.md`

## 背景

原版 z-order 操作准备（`zh9.p`，zh9.java:276-354）把页面 z
列表表示为 `ssc` 条目序列：**组成员坍缩成一条以组 id 为键、
`c=true` 的条目**（z 取组内最大值），未组化元素以元素 id 为
键。操作语义由三个集合决定：

- `rsc.b` = 可动集：只收 `!c && 已选.contains(元素id)` 的条目；
- `rsc.c` = 已选集：全部是**元素 id**（`ktc.f()` 交集），
  不含组 id。

`py` case26 的邻居门是 `!rsc.c.contains(相邻.a)`：相邻组条目
的 `a` 是组 id，`contains` 永不命中 → **组条目无论是否被选中
都是"未选邻居"**，已选元素照常交换/越过（越过组时取
`组z±1`）。只有相邻的已选非组元素才真正阻挡。

Harmony `movePageElementRefsOneStep` 此前以
`!selectedUnits.has(邻居.id)` 判定，**选中组单元被当成阻挡者**：
已选元素与已选组相邻时元素停住不动——偏离原版语义。

## 决策

1. `movePageElementRefsOneStep` 的阻挡判定从"邻居 id 在
   selectedUnits"收敛为"邻居是**已选非组单元**"
   （`selectedUnits.has(unit.id) && !unit.group`）。
2. 组单元（含选中组）在一步移动中恒为未选邻居：相邻元素
   组条目继续走既有 `neighbor.zIndex ± 1` 越过路径，相邻
   元素条目继续直接互换 z。
3. 移动者门 `selectedUnits.has(unit.id) && !unit.group` 不变
   ——等价原版 `contains(元素id) && !c` 的双重保险。
4. `movePageElementRefsToExtreme` 不改：moving=已选非组单元、
   staying=其余全部（含选中组），已与 `cfc` case8/9 等价。
5. 纯组选中 → 可动集为空 → 静默无操作，等价 `rsc.b` 空集。

## 已知边界（fail-closed）

原版 `zh9` 对组条目 z 取**组内最大 z**（`undVar.b`），Harmony
的 group 单元 z 取 `min(member.zIndex)`（层序代表值）。两处
对"越过组"的结果（`组z±1`）在排序投影上等价——只要组内
成员保持连续占据同一区段，代表值的偏移不改变最终层序；
若未来原版证据表明组内成员允许与外部元素交错，需重审。

## 影响

- `note/src/main/ets/core/model/PageElementOrder.ets`：一步
  移动阻挡判定收敛。
- `docs/migration/replays/d02-local-z-order-one-step.mjs`：
  模拟器同步收敛 + 新增"选中组邻居"前后向用例 + zh9 源码
  证据断言。
