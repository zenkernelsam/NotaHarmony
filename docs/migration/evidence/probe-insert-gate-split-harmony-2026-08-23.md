# 剪贴板探测与插入门禁分离证据

证据时间：2026-08-23（Asia/Shanghai）

## 缺陷模型

Phase 300 后顺序为同步占用 busy → await MIME probe。若此期间剪贴板 update 到达，旧
`refreshSystemClipboardImageAvailability()` 因 `canStartOriginalPhotoInsert()` 包含 busy 而立即置 false。
粘贴完成后系统剪贴板可能仍是 PixelMap，但缓存已丢失。

## Phase 301 契约

1. probe gate 不检查 `photoImportBusy`；
2. probe gate 仍检查 loaded、dataLoading/dataLoadFailed、historyBusy、persistence 和 pageId；
3. 异步回写继续校验 generation 和同一 probe gate；
4. 执行入口与菜单可见性继续由 `canUseOriginalClipboardImage()` 要求非 busy；
5. busy 只是插入槽位，不是“系统剪贴板元数据失效”。

本阶段未启动模拟器、虚拟机、真机或 Hypium。
