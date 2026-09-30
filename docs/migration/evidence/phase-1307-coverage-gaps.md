# Phase 1307 证据 — Harmony 覆盖缺口分析

来源：`note/src/main/ets/` 与原版普查对照。

## 已实现（Harmony 主体）

```
CRDT op+同步      BinaryOpCodec/*OpCodec/OpStore/
                  OperationCompaction/IncomingOperation
                  SyncCoordinator
编辑器            ui/editor/{Stylus,Canvas,Page,Zoom,
                  PageManager,Toolbar}
录音              OriginalRecording{Capture,Playback,
                  Microphone,InternalAudio,Delete,
                  Session}* —— 麦克风+内录后端
搜索索引          SearchIndexPolicy/SearchItemType/SearchText
手写识别抽象      OriginalHandwritingProviderCapability
                  Policy + RecognitionProvider
备份/资产         Backup*/Asset*
卡片/库/设置/主题  noteformability/pages + ui/library+
                  settings+theme
```

## 缺口（原版有、Harmony 未实现/降级）

```
billing/subscription  — 无文件 → Play/Samsung IAP 未移植
                        → fail-closed（Harmony IAP 待做）
OAuth login           — 无 login/auth → Google/MS/Apple
                        登录未移植 → 降级
live transcription    — 录音有但语音转写模块缺
search FTS engine     — 索引类型有、FTS 引擎本体待核
handwriting engine    — 抽象层有、MyScript 引擎 fail-closed
```

## 语义

Harmony = **笔记核心**（CRDT/编辑器/录音/搜索索引/
手写抽象/备份/卡片/库）已实现；**平台依赖**（IAP/
OAuth/转写/手写引擎）降级或未做 —— 明确的 fail-
closed 边界。

## Harmony 决策

平台依赖功能 → fail-closed ADR 或平台等价物；核心
功能已映射 —— 缺口清单驱动后续 Phase。

## 产出

- fixture `d02-coverage-gaps.mjs`（10 断言）。
- ADR-1251；中文报告。
