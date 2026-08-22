# ADR-0278: Serialize Paste Entry Before Recheck

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 299 在权限前复查当前 MIME 可用性，但复查发生在设置 `photoImportBusy` 之前。异步复查窗口内快速
第二次点击可通过同一门禁，造成两次权限/读取/插入流程竞争。

## Decision

粘贴入口先同步占用 `photoImportBusy`，再在 try 内执行当前 MIME availability probe；probe false/reject 清缓存
并返回。后续调用被统一页面门禁拒绝。通过复查后继续 exact READ_PASTEBOARD gateway、PixelMap 读取和原版
规范化链。finally 保证占用释放。
