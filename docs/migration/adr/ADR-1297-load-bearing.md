# ADR-1297：承重基线引用验证（正确）

## 状态

已接受（Phase 1356）。

## 决策

承重引用 `exc.A0`（比较器）+`haa`（op 枚举）+`cee`/
`uq9`/`tmf`/`qo5` 经实读验证**正确** —— CRDT 互操作
结论稳固，区别于算法层已更正的误标。

## 理由

实读 decompiled：`exc.A0` 默认比较方法存在；`haa`=
op 枚举（`SET_METADATA(1)`/`CREATE_PAGE(3)`/`INSERT_
CHAR(7)`/`REMOVE_CHARS(10)`/`REVIVE_CHARS(11)`/`CREATE_
INK(15)`…）字节值对照原版；`cee` FlatBuffer Table +
`uq9`/`tmf`/`qo5` 实体/时间戳。

## 后果

CRDT 线格式互操作结论**成立**（承重证据正确）；
算法层误标不影响此结论。
