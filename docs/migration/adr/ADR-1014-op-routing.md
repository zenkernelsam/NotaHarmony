# ADR-1014：op→实体 id 路由（fsi）

## 状态

已接受（Phase 1070）。

## 决策

- `fsi.F`：CREATE_* op → 受影响实体 id（`o09` 单 id；
  CREATE_PAGE → `nti.g(opId,i)` 页 id 区间）。
- `fsi.G/H`：仅 DELETE_ENTITIES 列举删除实体。

## 依据

op 序位 switch + `ln2.m()` 页数循环 + `yq9.a` 类型门控。

## 后果

Harmony 同步/索引按此路由定位受影响实体；CREATE_PAGE
多页用 `nti.g` 派生连续页 id。
