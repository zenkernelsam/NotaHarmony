# ADR-0270: Photo Insert Immediate Decode Refresh

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

照片/剪贴板插入复用既有 durable asset transaction，但运行时成功路径只把新 `ImageElement` 加入
`imageBlocks` 后直接重绘。共享解码缓存仍没有新 asset 的 entry；`renderFrame()` 只渲染 READY 缓存，
因此首帧不可见。旧实现依赖 `assetAvailabilityHub.publish()` 触发回调，而该回调先遍历 `imageBlocks`
查找相同 storageHash；新增 block 尚未参与查找时事件被吞掉。重启后调用全量刷新才可见。

## Decision

在当前页代与页 ID 校验通过后，安装新 blocks 时立即调用现有 `refreshImageAssets(generation, pageId)`。
该函数递增 asset generation、释放旧解码结果并按最终 `imageBlocks` 发起异步加载；加载完成后由既有
generation guard 写入缓存并强制重绘。

持久化事务、history 顺序和 availability hub 协议保持不变。本修复只恢复 runtime UI 与 durable state
的即时一致性。

## Consequences

- 新图片在同一会话内进入标准异步 decode 流程，不再等待重启或外部资产事件；
- generation guard 防止页切换或并发刷新后的过期解码覆盖当前页面；
- 设备端大图内存与首帧时延仍需后续真实设备验收。
