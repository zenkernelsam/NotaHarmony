# ADR-1061：字节漏斗 CharSequence + op 访问器 + holder 注册表

## 状态

已接受（Phase 1117）。

## 决策

- `v71` = ByteBufferBackedCharSequence —— 只写字节通道
  （`e()/f(bb)`），逐字符访问抛错。
- `uq9` = op 表：`l()→qo5`、`m()→haa`、`j()→tmf`、`k()→long`；
  eq/hash = {type,id,transient}。
- `sg5` = holder 注册表（Id/SeqId/StyleMap/RecordingSegment/
  Point/Size/ModifyPosition/DuplicateOp/OpAck/Op 委托 holder）；
  `sg5.b` = ThreadLocal scratch。

## 依据

字节视图禁字符读 + op 三键等值 + `v1b` holder 委托数组。

## 后果

Harmony：字节字段 = ArrayBuffer 视图禁逐字访问；op 等值
三键；holder 用 thread-local/惰性槽复刻。
