# ADR-1080：集合门面 + Ref 捕获类

## 状态

已接受（Phase 1136）。

## 决策

- `au1` = Kotlin 集合门面：`c1`/`f1`=first、`e1`/`g1`=
  firstOrNull/getOrNull、`h1`=intersect→LinkedHashSet。
- `mnb/hnb/knb` = Kotlin `Ref.{Object,Boolean,Int}Ref`
  —— DFS 回调 lambda 跨闭包捕获的可变 box。

## 依据

`g1` = `list.getOrNull(i)`；`*nb{I}` 单字段 Serializable
外壳。

## 后果

Harmony：用一等集合函数；Ref 捕获以 `{I}`/可变闭包
等价，无需单独类。
