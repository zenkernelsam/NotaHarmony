# 授权后切页粘贴中止证据

证据时间：2026-08-23（Asia/Shanghai）

## Harmony 竞态

Phase 303 的授权前守卫位于 `ensureOriginalClipboardReadPermission()` 之前。授权 promise 挂起期间可发生页面切换；
`pageLoadGeneration` 与 `loadedPageId` 随之改变。旧 promise resolve 后，原流程继续调用
`importOriginalClipboardImage()` 和 `insertOriginalPhotos()`。后者会捕获切换后的当前页快照用于渲染，但插入计划
仍以入口捕获的旧页上下文准备并持久化到旧页。

## Phase 304 契约

1. 权限网关返回 granted 后立即比较 `pasteGeneration/pastePageId`；
2. generation 或 pageId 不匹配时静默返回，避免跨页副作用；
3. 不读取 PasteData，不请求 PixelMap，不解码或编码图像；
4. 不构造 pending draft，不推进 undo history，不写数据库资产或元素表；
5. 同页路径保留 Phase 299–303 全部 MIME、busy、缓存重同步与 fail-closed 契约。

## 边界

本证据为静态时序契约与 Desktop Replay 断言；真实系统授权弹窗、pasteboard 更新合并和厂商时序仍需设备验收。
本阶段未启动模拟器、虚拟机、真机或 Hypium。
