# ADR-0280: Resynchronize Clipboard Cache After Paste

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

粘贴执行会读取系统 PixelMap，但不会改变剪贴板内容；期间外部 update 可能刷新缓存。Phase 301 允许忙碌期
probe，但完成后没有统一重同步点：若 update 事件丢失、迟到结果被 generation 丢弃或部分插入失败，缓存可能
继续保留过期 true/false。

## Decision

粘贴数据流程结束后，以实际 `PhotoInsertOutcome.insertedCount` 和一次新的 MIME probe 重同步
`systemClipboardImageAvailable`。probe reject 时 `isOriginalClipboardImageAvailable()` 已 fail closed 为 false。
该动作不读取 PasteData、不解码图像，也不请求权限；权限与数据读取仍只发生在既有 gateway 后。
