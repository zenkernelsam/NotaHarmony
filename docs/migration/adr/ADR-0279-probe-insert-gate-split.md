# ADR-0279: Separate Clipboard Probe and Insert Gates

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 300 让粘贴执行先同步占用 `photoImportBusy`。但 MIME probe 的页面门禁也检查同一 busy 标志：执行期间
SystemPasteboard update 触发刷新会立即清空可用性缓存；粘贴完成后菜单可能错误消失。

## Decision

拆分两类门禁：

- `canStartOriginalPhotoInsert()` 继续包含 busy，用于照片/粘贴执行；
- 新增 `canProbeOriginalClipboardImage()` 只排除数据加载、历史恢复等真实页面失效状态，允许忙碌期间探测。
- MIME probe 回写继续校验请求代数和 probe gate；菜单显示与粘贴执行仍使用 `canUseOriginalClipboardImage()`
  并要求非 busy 与缓存可用。
