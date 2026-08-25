# Harmony 证据 — 图片裁剪绕过照片导入租约缺口

- 缺陷时序：
  - 用户可在照片导入开始前选中单张图片并打开裁剪会话；
  - 照片导入随后持有父级和 Canvas 共享租约；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除 `photoImportBusy` 或回报父页；
  - `confirmImageCrop()` 原只检查 `historyBusy`，可替换图像数组并推入撤销记录；
  - 裁剪持久化和照片插入按捕获上下文合并，造成图像内容、顺序或撤销状态竞争。
- 影响边界：触摸入口已阻止在共享租约活动时新建交互；本缺口覆盖“先开裁剪会话、后启动
  导入”的既有会话确认路径。
- 修复事实：`startImageCrop()` 和 `confirmImageCrop()` 在 `historyBusy` 前拒绝
  `photoImportBusy`。拖拽/重置/取消等非提交操作保留；不改变裁剪算法或撤销动作类型。
- 验证：新增 `d02-image-crop-shared-lease-bound.mjs` 锁定启动/确认双层守卫及检查顺序；
  当前输出 `TOTAL=8 FAILED=0`。
