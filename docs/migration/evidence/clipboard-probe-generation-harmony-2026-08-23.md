# 剪贴板可用性探测代数证据

证据时间：2026-08-23（Asia/Shanghai）

## 缺陷模型

Phase 296 的 update listener 只检查 `canStartOriginalPhotoInsert()`。该条件不包含请求顺序，因此：

1. update A 启动慢 probe；
2. update B 或页面切换启动新 probe；
3. A 的旧 promise 最后 resolve；
4. A 的 true/false 可能覆盖 B 的最新结果。

## Phase 297 契约

1. 每次刷新递增 `systemClipboardImageProbeGeneration`；
2. promise 回写必须满足 `probeGeneration === systemClipboardImageProbeGeneration`；
3. 同一回调仍必须满足页面插入就绪条件；
4. 切页、生命周期清理和后续刷新都会自然使旧代数失效；
5. MIME probe 本身继续 exact 匹配 `MIMETYPE_PIXELMAP` 且异常 false。

本阶段未启动模拟器、虚拟机、真机或 Hypium。
