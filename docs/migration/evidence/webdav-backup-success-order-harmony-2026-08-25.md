# Harmony 证据 — WebDAV 备份成功顺序绑定

- 文件：`note/src/main/ets/ui/settings/BackupPage.ets`
- 方法：`backupAll()`
- 现场状态：Phase 438 后补审发现成功发布后先 `await WebDAVConfigStore.setLastBackup()`，再检查
  `isStale(lifecycleGeneration)`。
- 缺陷链：页面在持久化 await 期间销毁或被新一代操作替换时，过期续体仍会写入“上次备份”；同时该路径
  提前返回会跳过 `finally`，导致进程级 `backupOperationLease` 永不释放。
- 失败路径证据：发布失败和 catch 内的过期分支都提前返回；由于存在 `finally`，它们原本仍会释放租约。
  本次以 Replay 锁定这一既有安全语义，防止回归。
- 修复：当前代成功续体必须先通过 generation/disposal 门禁，再执行目标绑定的 last-backup 持久化；
  随后才更新 UI。所有异常和提前返回统一依赖 `finally` 重置 busy/status 并幂等释放租约。
- 范围：只改变 WebDAV 备份成功副作用顺序和守卫边界；批次上传、manifest 读回校验、恢复流程、
  配置快照和目标身份绑定保持不变。
