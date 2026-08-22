# 剪贴板图片可用性探测证据

证据时间：2026-08-23（Asia/Shanghai）

## 原版行为

`x7j.c(ClipboardManager)` 通过 `getPrimaryClipDescription()` 与
`hasMimeType("image/*")` 判定图片剪贴板；描述为空或不含图片 MIME 返回 false。`w43` 把该结果映射成
`e8a.a=ClipboardImage`，`v49` 才在 Paste 菜单分流到专用图片 handler。

因此原版菜单可见性来自剪贴板描述元数据，而不是先完整读取 bitmap 或先执行粘贴。

## HarmonyOS SDK 契约

本地 DevEco OpenHarmony `@ohos.pasteboard.d.ts` 声明：

- `SystemPasteboard.getMimeTypes(): Promise<Array<string>>`，since 14；
- 该 API 返回 pasteboard 中的 MIME 类型；
- 该声明块没有 `@permission ohos.permission.READ_PASTEBOARD` 注解；
- 对照 `getData(): Promise<PasteData>` since 12 重载明确标注 READ_PASTEBOARD 并可能抛 BusinessError 201。

因此 Harmony 可以用只读 MIME 元数据决定菜单可见性，把真实数据访问保留给用户点击后的授权链路。

## Phase 295 边界

1. 生产探测只比较 `pasteboard.MIMETYPE_PIXELMAP`；
2. 探测 promise reject 时 `isOriginalClipboardImageAvailable()` 返回 false；
3. 页面加载成功刷新探测结果，页面切换先清 false；
4. 菜单仍要求编辑器就绪且内部元素剪贴板为空；
5. 实际粘贴仍先请求 READ_PASTEBOARD，再调用 `getData()/getPrimaryPixelMap()`。

本阶段未启动模拟器、虚拟机、真机或 Hypium。
