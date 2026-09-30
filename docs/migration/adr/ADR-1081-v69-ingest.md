# ADR-1081：v69 挂起 op 调和入口

## 状态

已接受（Phase 1137）。

## 决策

- `v69.c(ff2)` = suspend 调和：版本++→快照实体表→
  遍历 `qja` 活实体（`k85`）→`ba6.K` 墓碑剔除→`k85.M()`
  pending ops→`so5.a` LWW 去重→应用。
- `w/x/y` = 同续体分批/收集辅助。

## 依据

`s69` 状态机 + `qja.I.values()` + `k85.M()` + dedupe。

## 后果

Harmony：async 调和协程；快照表 + 墓碑剔除 + LWW
去重 pending，逐 op 应用。
