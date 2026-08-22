# ADR-0275: Clipboard Availability Probe Generations

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 296 让 SystemPasteboard update 事件触发 MIME probe，但 probe 是异步 promise。连续 update、页面切换
或生命周期清理后，较早请求的迟到结果可能晚于新请求返回；若只检查当前编辑器就绪，旧结果仍可能覆盖新状态。

## Decision

每次 `refreshSystemClipboardImageAvailability()` 先递增 probe generation，并在 promise 回写时同时校验：
请求代数仍是最新、页面仍处于可插入状态。切页、生命周期清理或后续 update 触发的新刷新都会使旧代数失效。
探测失败继续由 `isOriginalClipboardImageAvailable()` fail closed。
