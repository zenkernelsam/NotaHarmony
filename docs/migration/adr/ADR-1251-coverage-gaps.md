# ADR-1251：Harmony 覆盖缺口

## 状态

已接受（Phase 1307）。

## 决策

平台依赖功能（billing/OAuth/转写/手写引擎）→ fail-
closed ADR 或平台等价物；笔记核心已实现。

## 理由

Harmony 已实现：CRDT op+同步、编辑器（触控笔/画布/
页管理）、录音（麦克风+内录后端）、搜索索引类型、
手写识别抽象（`RecognitionProvider`/`Handwriting
ProviderCapabilityPolicy`）、备份/资产/卡片/库/设置/
主题。**缺口**：billing/IAP（无）、OAuth login（无）、
live-transcription（无）、搜索 FTS 引擎本体（待核）、
MyScript 引擎（fail-closed）—— 平台依赖未移植。

## 后果

缺口清单驱动后续 Phase —— 平台依赖功能 fail-closed
或平台等价物；核心语义已保真。
