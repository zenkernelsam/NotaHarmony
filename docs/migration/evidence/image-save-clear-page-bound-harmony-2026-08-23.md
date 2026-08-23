# 图片插入成功状态跨页绑定证据

证据时间：2026-08-23（Asia/Shanghai）

## 竞态

`insertOriginalPhotos()` 的每张 SQLite 提交都是异步边界。用户在多图导入中途切换页面或笔记后，旧流程可以继续把
成功前缀提交到旧页；这部分持久化语义由既有页面快照守卫。但随后的无条件 `saveFailed = false` 是全局编辑器状态，
会把新页的真实保存失败误清。

## Phase 307 契约

1. 完全成功清除 `saveFailed` 前，必须满足 generation/pageId/currentPage 匹配；
2. 存在严格成功前缀（`partialFailure = true`）时继续不清 `saveFailed`；
3. 跨页完全成功仍返回 outcome，保留 undo history 和数据库结果；
4. 失败路径继续遵循 Phase 305 的同页报告契约；
5. 不改变多图逐张事务边界和“不声称跨图 rollback”的边界。

## 边界

真实多图中断、切页时序和数据库故障注入需要设备验收。本阶段只做静态契约、Desktop Replay 和双 HAP 打包；
未启动模拟器、虚拟机、真机或 Hypium。
