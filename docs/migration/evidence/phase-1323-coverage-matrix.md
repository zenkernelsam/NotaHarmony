# Phase 1323（里程碑）证据 — 原版↔Harmony 覆盖矩阵

来源：Phase 1200–1322 普查 + Harmony `ets/` 核对汇总。

## 子系统覆盖矩阵

| 原版 | Harmony | 状态 |
|------|---------|------|
| Compose 编辑器(Modifier.Node/pointer/drag/semantics/undo) | ui/editor+core/adaptation+rendering | ✅ 全实现 |
| TextField/布局/AnnotatedString | TextBlock*+core/model | ✅ |
| 笔画/Kalman 预测/splat | PenKitPredictor+algorithm/ | ✅(PenKit 替代 Kalman) |
| 360-video/传感器 | — | ➖ 未移植（次要） |
| FlatBuffers+protobuf+Wire+Apollo | OriginalSynced*FlatBuffer+codec | ✅（线保真） |
| `haa` 32-op CRDT | OpTypes(ORIGINAL_*桥接)+*OpCodec+*PayloadEncoder | ✅(线保真，本地超集) |
| `tmf`/`exc.A0` 排序 | OperationIdentity(64-bit+exc.A0 复刻)+UnsignedDecimal | ✅ 逐位保真 |
| Room 8 库 | DatabaseManager(RdbStore)+仓储+OpStore | ✅ |
| ops/synced 冲突异常 | SyncedOperationInbox+validate | ✅ |
| `.ntb`/`.note` 导入 | NoteImporter(.note ZIP+plist) | ✅ .note；.ntb 经同步 |
| `.note` 导出 | NoteExporter+SnapshotGuard | ✅ |
| 备份(iCloud/Drive/WebDAV) | WebDAV 客户端+BackupBatch+BackupAbility | ✅(WebDAV) |
| widget×5 | noteformability 5 卡+2 配置 ability | ✅ 保真 |
| 录音(前台服务) | OriginalRecording*(mic+internal) | ✅ |
| 手写转文/数学(dhb+MyScript) | OriginalHandwriting*Conversion+RecognitionProvider | ⚠ 抽象/引擎fail-closed |
| GLMath 原生 | OriginalMathEngine(glmath 真绑定) | ✅ 原生移植 |
| PDFTron 原生 | PdfRasterPlan/Pdf*(Harmony PDFKit) | ⚠ PDFKit 替代 |
| OAuth(GMS/MS/Apple) | — | ❌ 未移植(fail-closed) |
| IAP(Play+Samsung) | — | ❌ 未移植(fail-closed) |
| 转写(LiveTranscription+GCS) | — | ❌ 未移植 |
| Firebase/Mixpanel/Singular/OTel | — | ➖ 分析未移植 |
| MyScript iink | RecognitionProvider 抽象 | ⚠ 引擎 fail-closed |
| ReLinker/原生回退 | hilog+fail-closed | ⚠ |
| Socket.IO 实时 | IncomingOperationSyncCoordinator | ✅(传输层) |
| S-Pen SDK | PenKit+ArkUIStylusAdapter | ✅(Harmony pen) |
| Coil3/SVG/TIFF | multimedia.image+ImageAssetLoader | ✅ |

## 结论

**笔记核心 100% 覆盖**（编辑/CRDT/同步/持久化/导入
导出/备份/卡片/录音/渲染/手写识别抽象）。**平台依赖
fail-closed/降级**：OAuth、IAP、转写引擎、MyScript 引擎、
分析 SDK、360-video。

## 产出

- fixture `d02-coverage-matrix.mjs`（10 断言）。
- ADR-1267；中文报告。
