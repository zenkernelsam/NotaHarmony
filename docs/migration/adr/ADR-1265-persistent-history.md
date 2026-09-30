# ADR-1265：持久化历史 + u64

## 状态

已接受（Phase 1321）。

## 决策

撤销 = op-log 归约（持久化派生，跨会话恢复）；
u64 timestamp/siteId 用十进制字符串（JS 无 u64）。

## 理由

`PersistentHistory`（`reducePersistentHistory` 按
client_time+sequence 序把 op 日志归约为 undo/redo 栈
+页变更/结构 op 分类）+ `UnsignedDecimal`（u64
canonical/exhausted）—— 持久化撤销（vs 原版内存栈）
+u64 保真。

## 后果

undo/redo 可持久化恢复（原版会话级）—— 语义增强；
u64 十进制保真原版序。
