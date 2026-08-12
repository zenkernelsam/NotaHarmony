# ADR-0162：资料库笔记变更顺序

## 决策

`LibraryViewModel` 的创建和删除通过同一个 promise 队列串行执行，并在各自事务成功后
刷新列表。失败不会阻断后续变更。

## 原因

UI 原有 create/delete 两个独立 busy 标志，允许两种操作同时修改仓储并交错刷新；
generation 只能抑制旧查询结果，不能定义两个写操作的业务顺序。

## 边界

绕过 `LibraryViewModel` 直接调用仓储的后台同步仍需仓储级统一写者策略；本 ADR 约束
资料库 UI 入口。
