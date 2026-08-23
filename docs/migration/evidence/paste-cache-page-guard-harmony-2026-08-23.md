# 粘贴完成剪贴板缓存页面守卫证据

证据时间：2026-08-23（Asia/Shanghai）

## 竞态

`startOriginalClipboardImagePaste()` 通过入口门禁后包含多次 await。若用户在授权、PixelMap 规范化、持久化
插入期间切页，Phase 302 的完成赋值会以旧操作结果覆盖新页面的 `systemClipboardImageAvailable`。早期
“不可用即清 false”的路径也可能误清新页状态。

## Phase 303 契约

1. 入口捕获当前 `pageLoadGeneration` 与 `loadedPageId`；
2. 早退 MIME probe 只在相同页面上下文写 false；
3. 授权前确认页面未切换，避免旧流程继续读取数据；
4. 完成后仍做一次无权限 MIME probe，且只允许相同 generation/pageId 回写；
5. probe 继续不读取 PasteData、不解码 PixelMap、不请求 READ_PASTEBOARD；
6. 持久化与渲染由 `insertOriginalPhotos()` 捕获的页面上下文继续守卫。

## 边界

本证据基于源码静态契约与 Desktop Replay；真实跨页时序、事件合并和厂商行为仍需设备验收。本阶段未启动模拟器、
虚拟机、真机或 Hypium。