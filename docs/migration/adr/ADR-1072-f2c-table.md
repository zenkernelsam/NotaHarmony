# ADR-1072：f2c 序列元素表

## 状态

已接受（Phase 1128）。

## 决策

- `f2c` = FB 表 `{slot4: [cxc]@12B, slot6: qo5}`。
- `l(i,cxc)` = 步长 `i*12` 绑读；`k()` 嵌读 opId。

## 依据

12-byte cxc 步长 = exc 锚 struct 同构。

## 后果

Harmony 序列元素 wire = `{锚向量@12B, opId}`；步长绑读。
