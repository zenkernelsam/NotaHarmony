# ADR-1073：LWW tombstone map

## 状态

已接受（Phase 1129）。

## 决策

- `al2` = tombstone map：`b(bl2)` 仅当 `so5.a(旧opId, 新opId)
  <=0` 才写 —— 删除走 LWW 收敛。
- `al2(cl2)`/`a()→cl2` = builder↔snapshot 循环。

## 依据

opId 序守卫防旧 tombstone 覆盖新 op（因果收敛）。

## 后果

Harmony tombstone 保留 opId LWW 守卫 —— 不是单纯
hash-set；收敛性依赖此序。
