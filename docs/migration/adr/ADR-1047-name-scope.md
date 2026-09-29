# ADR-1047：Name 值类 + 作用域树 + 标记接口

## 状态

已接受（Phase 1103）。

## 决策

- `ym8` = Kotlin `Name`（`e`/`g`/`d`/`f` + asString 系列），
  `<…>` 特殊名。
- `xt4`/`wt4` = 点分隔 FqName 作用域树（`a(ym8)→child`，
  `e()→parent`，`<root>` 根）。
- `uz`/`rr6`/`hli` = 标记/sink 接口。

## 依据

Kotlin 编译器名解析 vendored；仅序列化内部用。

## 后果

Harmony 无作用域解析需求 → fail-closed 直移 Name 语义备用；
标记接口保留结构。
