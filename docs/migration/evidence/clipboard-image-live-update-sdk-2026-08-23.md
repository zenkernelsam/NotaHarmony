# 剪贴板图片可用性实时更新证据

证据时间：2026-08-23（Asia/Shanghai）

## 原版行为

Android `w43` 在菜单状态构造时调用 `x7j.c(ClipboardManager)`，后者每次读取当前
`getPrimaryClipDescription().hasMimeType("image/*")`。因此剪贴板内容变化会反映到后续 Paste 菜单判定；
原版不是在编辑器生命周期里缓存一次结果。

## HarmonyOS SDK 契约

本地 DevEco OpenHarmony `@ohos.pasteboard.d.ts`：

- `SystemPasteboard.on(type: 'update', callback: () => void)` 自 API 7 存在；
- 注释明确为“Callback invoked when pasteboard content changes”；
- `off(type: 'update', callback?)` 支持按同一 callback 移除；
- 该事件声明没有 READ_PASTEBOARD 权限注解；受权读取仍属于后续 `getData()`。

## Phase 296 边界

1. 组件出现订阅一次，组件消失精确移除同一 callback；
2. update 事件只触发 MIME probe，不读取 PasteData、不解码 PixelMap；
3. probe reject 或事件 API 异常均 fail closed 并记录日志；
4. 页面切换先清 false；异步 probe 回写继续检查当前页面就绪条件；
5. 点击后的 READ_PASTEBOARD 请求与数据读取契约不变。

本阶段未启动模拟器、虚拟机、真机或 Hypium。
