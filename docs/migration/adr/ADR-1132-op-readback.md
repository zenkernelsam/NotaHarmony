# ADR-1132：op 载荷回读（cee/ka4/vq9→uq9）

## 状态

已接受（Phase 1188）。

## 决策

`vq9 extends cee implements ka4` CREATE op 载荷（`k()→
qo5` opId 回读 + `a()/j()/l()` 字段 + `n()→uq9` 包装）→
Harmony op-payload struct + rebuild-opId + into-op —
`ka4` 统一载荷契约（同 Phase 1096-1098 层）。

## 理由

`extends cee implements ka4` + `k()→qo5`（buffer→`qo5.b`）
+ `m()/n()→uq9` + `c(8)` 槽读。

## 后果

op 解包/重组桥：载荷表→opId+字段→完整 `uq9` op；
Harmony 沿用同一载荷→op 模式。
