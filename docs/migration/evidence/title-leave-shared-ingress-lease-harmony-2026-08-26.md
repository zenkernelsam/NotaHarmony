# Harmony 证据 — 标题与离开流程绕过共享租约

- 缺陷时序：
  - 照片导入持有父级 `photoImportLeaseActive`；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除共享租约或回报父页；
  - 返回按钮可进入离开流程，排队标题也可继续提交；
  - 标题路径捕获选中页、准备历史并写 SET_METADATA；
  - 离开路径还会 flush 页面、释放资源并路由返回。
- 影响边界：NOTE_TITLE 历史与页面 flush 可在照片结果合并前竞争；提前路由可能把
  收口续体留在旧页面上下文。
- 修复事实：离开和标题提交都在共享导入与结构租约处 fail closed。幂等标题发布、
  失败恢复、销毁守卫和页面身份校验不变。
- 验证：新增 `d02-title-shared-ingress-lease-bound.mjs`，当前 `TOTAL=10 FAILED=0`；
  相邻离开 Replay 与标题上下文 Replay 同步纳入共享租约断言。
