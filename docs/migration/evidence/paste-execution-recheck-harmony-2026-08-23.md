# 粘贴执行前可用性复查证据

证据时间：2026-08-23（Asia/Shanghai）

## 原版边界

Android `v49` 的 Paste 分流基于当前菜单状态对象；但 Harmony 的菜单点击是异步用户动作，缓存状态和实际
system pasteboard 可能在长按与点击之间变化。因此执行入口需要重新确认当前 MIME 元数据。

## Phase 299 契约

1. 执行前必须满足 `canUseOriginalClipboardImage()`；
2. 再调用 `isOriginalClipboardImageAvailable()` 获取当前 MIME probe；
3. false/reject 时清 `systemClipboardImageAvailable` 并返回；
4. 不触发 READ_PASTEBOARD 权限请求；
5. 不调用 `hasData()/getData()/getPrimaryPixelMap()`；
6. 通过复查后才进入权限网关与原版规范化粘贴。

本阶段未启动模拟器、虚拟机、真机或 Hypium。
