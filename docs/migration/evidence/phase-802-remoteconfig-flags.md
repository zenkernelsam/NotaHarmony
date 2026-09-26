# Phase 802 证据：RemoteConfig 特性开关面 delta

日期：2026-09-23
输入：`decompiled_{1.0.3,1.4.2}/resources/res/xml/core_remoteconfig__remote_config_defaults.xml`

原版通过 Firebase RemoteConfig 默认表给特性开关赋默认值。该文件完整列出
客户端全部特性门——是判断"1.4.2 新特性默认是否对最终用户开放"与
"1.0.3 既有特性是否已毕业"的最硬证据。

## 1. 开关总量与 delta

- 1.0.3：52 个 key
- 1.4.2：58 个 key（+32 / −26，净 +6）
- 共享 26 个 key 的默认值：**零翻转**（配对解析 25/51 项有显式 value，
  其余为 `<value/>` 空值；共享项值逐一相等）

## 2. 1.4.2 新增开关（32 项）及默认值

| 默认 | 开关 | 对应已登记 Phase |
|------|------|------------------|
| true | `androidImageBlockOcr` | 图片块 OCR（OCR 升级默认开） |
| true | `androidImeSessionTelemetry` | IME 会话遥测 |
| false | `androidGallery` | 774/789 gallery 社区 |
| false | `androidCalendarTimeline` | 765 calendar |
| false | `androidFinishMyNotes` | 786 Finish Notes AI |
| false | `androidLearnSyllabusImport` / `androidLearnExplainThis` | 772/788 Learn |
| false | `androidTextOnlyMode` | 773 text-only |
| false | `androidShapeTool` | 776 shape picker |
| false | `androidTypingSettings` / `androidMinLineSpacing`(=1.0) | 780 排版设置 |
| false | `androidRuler` | 782 直尺（1.0.3 无门→1.4.2 加门） |
| false | `androidHandwritingRecognitionOutOfProcess` / `androidMathHandwritingRecognition` / `androidRawContentHandwritingRecognition` | 768 HWR 三件套全部默认关 |
| false | `androidNoteLimitOfferSheet` / `androidStarterNoteLimit`(=30) | 788 免费额度付费墙 |
| false | `androidPhoneDifferentiatedUx` | 手机差异化 UX |
| false | `androidMarkdownAutoformat` | Markdown 自动排版（新） |
| false | `androidMultiSelectInkEffects` | 多选墨迹特效（新） |
| false | `androidScopedTileInvalidation` / `androidTileQueueDrainEmit` | 瓦片失效/队列遥测（渲染性能） |
| false | `androidNoteSnapshotCache` | 快照缓存（793 快照异常配套） |
| false | `androidRealtimeIdleTeardownSeconds`(=0) | 协作会话空闲回收 |
| false | `androidIntercomSupport` / `androidSamsungHashedAccountId` | 支持渠道/三星账号桥 |
| 空 | `androidPlayOfferIds{Lite,Plus,Pro}{Annual,Monthly}` | 三档订阅 offer 由服务端下发 |

## 3. 1.4.2 移除开关（26 项）= 特性毕业信号

`PartialEraser`、`Pencil`、`ZoomView`、`ShareNote`、`SnapToGrid`、
`LiveTranscription`、`ShowTranscripts`、`MathConversion`、
`HandwritingToText`、`DocumentScanning`、`VersionHistory`、`SmartNotes`、
`LearnChat`/`LearnQuizzes`/`LearnSummary`、`ViewOnly`、`MultiplayerPresence`、
`CollabRtlText`、`EntityGroups`、`DeselectMode`、`FolderEmojiPicker`、
`ShapeEditSnapping`、`StrokeStyle`、`ToolboxSecondaryTools`、
`NoteLimit`（→`StarterNoteLimit` 重构）、`PlayLaunchPromo`。

判定逻辑：这些特性在 1.4.2 的字符串/代码面均仍存在（前期 Phase 逐一获证），
开关消失意味着**毕业为无条件内置**，与 Phase 781"Learn 非下线而是改名重构"
的结论互证。`NoteLimit→StarterNoteLimit` 是第二次"改名重构"实例
（与 feature_settings→ui_account 同模式）。

## 4. 迁移含义

- 1.4.2 几乎所有新特性**默认关**（服务端 RemoteConfig 灰度/白名单控制）。
  Harmony 侧继续按 fail-closed 处理这些边界（gallery/calendar/FinishNotes/
  syllabus/订阅档位均属后端绑定面），与原版默认姿态一致，不损失默认体验。
- 1.0.3 门控特性在 1.4.2 全部毕业，证明 NotaHarmony 移植的功能面均为稳定
  内置面——基线选择正确。
- `androidImageBlockOcr` 默认开：图片块 OCR 属于 ML Kit 管线（proprietary），
  已属 fail-closed 边界。
- `androidPlayOfferIdsLite*`=空默认值：订阅档位三档化（新增 Lite）由服务端
  定价控制，客户端无逻辑可移植。
