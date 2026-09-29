# ADR-1007：CRDT Register = LWW（opId 全序）

## 状态

已接受（Phase 1063）。

## 决策

Harmony CRDT 寄存器采用原版 `fqb`/`yc6` LWW 语义：

- `c(op,v)` 仅当 `so5.a(op.l(), winner)>0` 覆盖；
- 比较器 = `compareUnsigned(logicalTime)` → `unsigned short site`；
- 时间戳 = `serverTime ?: clientTime`（fsi.J）。

## 依据

`qo5`（Phase 1040/1060）= OpId{site:short, logicalTime:int}；
无符号比较 = CRDT 收敛的关键——有符号比较会让负 logicalTime
永远输掉，破坏合并。

## 后果

Harmony 寄存器 = {winnerOpId, value, timestamp} 三元组；
merge 用同一比较器；确定性收敛，无需仲裁。
