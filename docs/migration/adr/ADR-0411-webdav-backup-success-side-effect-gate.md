# ADR-0411 — WebDAV 备份成功副作用门禁

日期：2026-08-25

## 决策

`backupAll()` 的成功续体必须在 WebDAV 批次读回验证之后、任何本地持久化副作用之前重新检查
lifecycle/disposal generation。只有当前代续体才能调用 `WebDAVConfigStore.setLastBackup()` 并发布 UI；
过期续体直接返回，由统一 `finally` 重置忙碌状态并释放进程级备份租约。

## 理由

“上次备份”是用户可见且跨启动保留的状态承诺。远端批次成功只代表备份包已发布；页面销毁或新一代操作
接管后，旧续体不再有权继续承诺本地备份时间。持久化放在门禁前会让不可见任务改写持久状态，而其提前
返回又会绕过 `finally`，造成全局备份入口死锁。

## 结果

- 成功副作用顺序固定为：publish/read-back → stale gate → setLastBackup → UI。
- 所有失败、异常和过期续体都经过同一 `finally` 清理路径。
- 不引入排队锁；第二个备份页仍按既有设计立即得到“操作进行中”反馈。
