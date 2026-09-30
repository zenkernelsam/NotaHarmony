# ADR-1089：k85/l85 成员集合 spec↔live

## 状态

已接受（Phase 1145）。

## 决策

- 成员集合 = 单 `fqb` "members" LWW reg 持 `List<opId>`。
- `l85`(spec,CREATE 造)↔`k85`(live)↔`yy3` 三段对称；
  `M()`=reg 值（live）/`xj2.v` 委托（spec）。

## 依据

`w1b "members"` 描述符 + `k85 M()=c.b` + `l85(uq9,cm2,
yc6)` CREATE-ctor + `xj2.v(d,h[0])`。

## 后果

Harmony：Register<List<opId>> 成员集合；改成员=整表
LWW 覆盖；`ba6.y/z` 读 `M()` 子表。
