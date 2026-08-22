# 粘贴入口串行化证据

证据时间：2026-08-23（Asia/Shanghai）

## 缺陷模型

Phase 299 的顺序是：

1. `canUseOriginalClipboardImage()`；
2. await MIME probe；
3. 设置 `photoImportBusy`。

第 2 步存在异步窗口，快速双击可两次进入并重复触发权限/读取/插入。

## Phase 300 契约

1. 统一门禁通过后立即同步设置 `photoImportBusy = true`；
2. MIME probe 在 try 内执行，probe false/reject 清 `systemClipboardImageAvailable` 并 return；
3. 后续点击因 busy 被统一门禁拒绝；
4. probe 通过后才允许 READ_PASTEBOARD gateway 和数据读取；
5. finally 始终释放 busy，不吞掉正常插入路径。

本阶段未启动模拟器、虚拟机、真机或 Hypium。
