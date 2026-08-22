# 粘贴完成剪贴板缓存重同步证据

证据时间：2026-08-23（Asia/Shanghai）

## 缓存风险

粘贴期间可能发生三类状态漂移：

1. SystemPasteboard update 事件被平台合并或延迟；
2. Phase 297 的 generation 守卫丢弃旧异步结果；
3. 部分插入失败后 UI 不应继续假设原入口必然可用。

## Phase 302 契约

1. 捕获 `insertOriginalPhotos()` 的 `PhotoInsertOutcome`；
2. 完成后执行一次新的 MIME availability probe；
3. 缓存等于 `probe && outcome.insertedCount > 0`；
4. probe 异常由 ingress fail closed 为 false；
5. 该重同步不读取 PasteData、不解码 PixelMap、不请求 READ_PASTEBOARD。

本阶段未启动模拟器、虚拟机、真机或 Hypium。
