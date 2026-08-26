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

## Phase 497 增量（2026-08-26）

- 继续补审发现：标题输入与点击编辑已拒绝共享租约，提交内部也有 fail-closed 防线；但
  `TextInput.onSubmit()` 与 `onBlur()` 直接调用 `saveTitle()`，晚到事件可先关闭编辑态并排队。
- 回车和失焦回调现在先拒绝 `photoImportLeaseActive`，再执行原有标题保存。序列化队列、幂等
  发布、失败恢复、离开兜底、销毁守卫和历史语义全部不变。
- 扩展既有标题共享租约 Replay 锁定两项新防线，当前 `TOTAL=12 FAILED=0`；相邻离开、上下文、
  历史、销毁和队列 Replay 全部通过。

## Phase 517 增量（2026-08-26）

- 继续补审发现：标题输入、回车与失焦只拒绝共享租约；页面 `pageLoadFailed` 或 `pageLoading` 时，
  晚到事件仍可更新草稿、退出编辑态并排队保存。
- 三项回调现在同时拒绝加载失败/加载中状态，再执行原草稿更新或 `saveTitle()`。序列化队列、幂等
  发布、失败恢复、销毁守卫和历史语义不变。
- 扩展既有标题共享租约 Replay 覆盖 `onChange/onSubmit/onBlur` 三项入口，当前
  `TOTAL=15 FAILED=0`。
