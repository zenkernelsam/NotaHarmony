# ADR-1055：hja/gja 持久 Map 语义

## 状态

已接受（Phase 1111）。

## 决策

- `hja` = PersistentMap：`put→新快照`（结构共享）、
  `builder()→gja` 瞬态 fork。
- `gja` = builder：`build()→hja` 冻结。
- `ik6`/`lk6` = 快照/builder 标记。

## 依据

`put` 返回 hja（非 void）= 不可变 assoc；builder/build 循环。

## 后果

Harmony：不可变 Map 拷贝 + freeze 复刻持久语义；实体/
tombstone store 全走 builder→snapshot 环。
