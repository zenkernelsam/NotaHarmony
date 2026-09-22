# Phase 625 — z-order 一步移动：选中组不阻挡交换（zh9/py case26）

## 原版证据

- `dhb.java` case6/7（SEND_FORWARD/SEND_BACKWARD）→
  `xsc.q` → `new py(…, 26)`；case8（SEND_TO_FRONT）→
  `new cfc(9)`、case9（SEND_TO_BACK）→ `new cfc(8)`——
  cfc 变体序 9=置顶、8=置底，与 dhb case 序交叉。
- `zh9.java` p()（:276-354）：z 列表逐元素建 `ssc` 条目——
  组成员以**组 id**（`undVar.a`）为键、`c=true`，z 取组内
  最大值（`undVar.b`）；`rsc.b` 只收 `!c && f().contains(id)`
  的未组化已选条目（:350）；`rsc.c` 为已选**元素 id** 集
  （:307 `ys2.J(ktcVar.f(), iterableP)`）。
- `py.java` case26：移动者门 `contains(a) && !c`，邻居门
  `!contains(相邻.a)`——相邻组条目的 `a` 是组 id，`contains`
  永不命中 → **选中组与普通未选组一样不阻挡交换**；相邻
  已选非组元素才阻挡。越过组时交换者取 `组z±1`，组原位
  不动。
- `cfc.java` case8/9：只对 `rsc.b` 分配极端段索引，组条目与
  未选元素保持原相对位次。

## 排查结论

Harmony `movePageElementRefsOneStep` 的邻居阻挡判定
`!selectedUnits.has(units[index+1].id)` 把**选中组单元也算作
阻挡者**：已选元素与已选组相邻时元素不再移动，违反
`py case26` 的"组 id 键永不命中已选元素 id 集"语义。
`movePageElementRefsToExtreme`（moving/staying 分离）已等价
`cfc`，无需修改。

## 修复

- `PageElementOrder.ets`：阻挡判定收敛为 `selectedUnits.has(
  unit.id) && !unit.group`——只有已选非组单元阻挡交换；组
  单元（含选中组）恒为未选邻居，元素按 `组z±1`/直接互换
  路径越过。
- 注释补 zh9 组键 + py case26 contains 语义引用。

## 回归验证

- `d02-local-z-order-one-step.mjs`：模拟器同步收敛 + 新增
  {A,G} 同选前向越过、{B,G} 同选后向越过用例 + zh9 源码
  证据断言 → PASS。
- `d02-original-tape-zorder.mjs`：7/7 PASS。
- 全量 Desktop Replay：514/514 PASS。
- `note@default` + `note@ohosTest` HAP 构建成功。

## 文件

- `note/src/main/ets/core/model/PageElementOrder.ets`
- `docs/migration/replays/d02-local-z-order-one-step.mjs`
- `docs/migration/evidence/original-z-order-selected-group-neighbor-2026-09-28.md`
- `docs/migration/adr/ADR-0594-original-z-order-selected-group-neighbor.md`
- `docs/migration/reports/phase-625-original-z-order-selected-group-neighbor.md`
