# 原版 1.4.2 模板同步管道登记（Phase 769 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/sources/com/gingerlabs/notability/data/templates/sync/`
>   + `data/settings/sync/TemplatePageSyncWorker.java`
>   + `defpackage/{s93,e93,kuc,bth,m93,l93}.java`
> 性质：1.4.2 版本差证据登记（Phase 764 schema 的同步侧补全）；无 Harmony 代码变更。

## 一、同步架构

两条 WorkManager 管道：

1. **`CustomTemplateSyncWorker`**（templates/sync/）→ 注入 `s93` 编排器。
   `s93` 持有 11 个协作者（e93/g83/i83/o83/q83/h93/k93/aa3/ulj/l6k/
   c40），带：
   - `oha l`/`oha o` 双互斥（入队/出队串行化）；
   - `AtomicInteger n` 进度计数；
   - `uw2` 未捕获异常通道（`zg9.SYNC` 域，"Uncaught custom template
     sync exception"）；
   - `l6k.b("CustomTemplateSync")` 分析打点。
   `b()` 为排空循环（mutex + 逐项 `e93.a()` 处理）；
   `e(ra3, ...)` 上传媒介方法落入 JADX 不可解集，登记为缺口。

2. **`TemplatePageSyncWorker`**（settings/sync/）→ 注入 `bth`
   页面级同步协调器（a/b/d/e 四个 suspend 操作）——与 Phase 767 的
   `TemplatePaperInfo.pendingSync` 列呼应：纸张页信息单独一条同步线。

3. **墓碑排空**：`kuc` 提供 `DELETE FROM PendingTemplateDeletion
   WHERE assetId IN (...)`——上传确认后批量出队（Phase 764 schema 的
   消费端）。

## 二、与 schema 的闭环

`CustomTemplate.uploadState`（TEXT）+ `syncedName` + `assetId` 三列
服务该管道：本地行 ↔ 远端资产映射由 assetId 维系，syncedName 记录
远端改名，uploadState 为状态机列（值枚举未在字面量中直接出现，
`UPDATE ... SET uploadState=? WHERE assetId=?` 带 id 守卫，见
Phase 764 证据）。

## 三、分类

模板云同步为**后端边界**：上传/删除/改名的对端均为 GingerLabs
模板服务，无公开协议文档；本地侧仅登记 schema 与排空语义，
维持 ADR-0708 fail-closed，不伪造同步端点。

## 四、静态缺口

- `s93.e()`（上传媒介）与部分 `bth` 方法体未反编译成功——登记为
  JADX 缺口，协议细节不可恢复。
- `uploadState` 的具体取值域未在字面量中出现；仅知其为 TEXT 状态列
  带 assetId 守卫更新。
