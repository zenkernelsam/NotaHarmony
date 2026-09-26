# Phase 802 报告：RemoteConfig 特性开关面 delta

日期：2026-09-23
Phase 类型：证据登记（无代码改动）

## 摘要

解析原版 `core_remoteconfig__remote_config_defaults.xml` 特性开关默认表，
得到 1.0.3（52 keys）↔ 1.4.2（58 keys）的完整门控面：+32/−26，共享开关
默认值零翻转。该面是判断新特性默认开放程度与既有特性毕业状态的最硬证据。

## 关键发现

### 1.4.2 新特性几乎全部默认关

32 个新增开关中，所有面向用户的功能特性默认 `false`：

- `androidGallery` / `androidCalendarTimeline` / `androidFinishMyNotes`
- `androidShapeTool` / `androidTextOnlyMode` / `androidTypingSettings`
- `androidHandwritingRecognitionOutOfProcess` / `androidMathHandwritingRecognition`
  / `androidRawContentHandwritingRecognition`（HWR 三件套全关）
- `androidLearnSyllabusImport` / `androidLearnExplainThis`
- `androidPhoneDifferentiatedUx` / `androidMarkdownAutoformat` /
  `androidMultiSelectInkEffects` / `androidScopedTileInvalidation` 等

即服务端 RemoteConfig 灰度控制——Harmony fail-closed 与原版默认体验一致。

例外：`androidImageBlockOcr`/`androidImeSessionTelemetry` 默认开；
`androidStarterNoteLimit=30`、`androidMinLineSpacing=1.0`、
`androidRealtimeIdleTeardownSeconds=0` 为标量默认；六个订阅 offer ID 默认空
（Lite 档为新增，定价全服务端下发）。

### 26 个移除开关 = 毕业信号而非下线

PartialEraser/Pencil/ZoomView/ShareNote/SnapToGrid/LiveTranscription/
MathConversion/HandwritingToText/DocumentScanning/VersionHistory/SmartNotes/
LearnChat/LearnQuizzes/LearnSummary/ViewOnly/MultiplayerPresence 等——其字符串
面在 1.4.2 全部保留（本 Phase fixture 获证），开关消失即毕业为无条件内置。
与 Phase 781"Learn 改名重构非下线"互证。

### ruler 特例

1.0.3 直尺无门内置 → 1.4.2 加 `androidRuler` 门且默认关——从"恒开"转为
服务端控制。Harmony 按 1.0.3 内置语义实现，与原版 1.0.3 行为一致，保留。

## 验证

- `d02-remoteconfig-flags.mjs`：8/8 green
- 全量 Desktop Replay：675/675 green
- 双 HAP：default + note@ohosTest 均成功（既有警告，无新增错误）

## 产物

- 证据：`docs/migration/evidence/phase-802-remoteconfig-flags.md`
- Replay：`docs/migration/replays/d02-remoteconfig-flags.mjs`
- ADR：`docs/migration/adr/ADR-0746-remoteconfig-flags.md`
