# ADR-1096：core/model 线模层

## 状态

已接受（Phase 1152）。

## 决策

- `core.model.a` = 笔记 bundle：`{bs1头, origin, name,
  opId, 4 实体图}` + 根页 sentinel `nti.g(rh8.b(0,-1),0)`。
- `core.model.c` = 页线模 `{op[], pageId, 子图}`。
- `core.model.b` = live→快照物化器（`a(a79)→th7`）。

## 依据

命名包 `core/model/` 字段 + sentinel + 物化器。

## 后果

Harmony：笔记/页线模 Record（存盘/同步载体）；
sentinel 根页约定保。
