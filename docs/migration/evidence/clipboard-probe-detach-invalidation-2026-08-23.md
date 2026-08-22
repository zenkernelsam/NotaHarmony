# 剪贴板探测退订失效证据

证据时间：2026-08-23（Asia/Shanghai）

## 缺陷模型

Phase 297 后，probe 回写需要请求 generation 最新并满足页面插入就绪。但生命周期退出时没有递增 generation；
若退出前已有 probe 启动，而退出后对象内缓存的 page/persistence 状态仍可能短暂满足判断，旧 promise 存在
回写窗口。

## Phase 298 契约

1. `stopSystemClipboardImageAvailabilityUpdates()` finally 必须递增 probe generation；
2. 同时清空 listener 引用和 `systemClipboardImageAvailable`；
3. 已启动 probe 因 generation 不匹配被丢弃；
4. 组件重新出现时重新订阅并从新代数刷新；
5. 不读取 PasteData、不解码 PixelMap、不提前请求 READ_PASTEBOARD。

本阶段未启动模拟器、虚拟机、真机或 Hypium。
