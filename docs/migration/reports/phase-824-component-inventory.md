# Phase 824 — Manifest 应用组件明细闭合

## 范围

三版 `AndroidManifest.xml` 的 receiver/service/provider 应用级逐项清单
与 Harmony 等价映射。

## 原版证据

- **Receiver**：6 个应用级三版零差——AppUpgradeReceiver
  （`MY_PACKAGE_REPLACED`）+ 5 个 widget provider（均声明
  APPWIDGET_UPDATE + LOCALE_CHANGED）。
- **Service**：2→2→3——1.4.2 新增 `HwrEngineService`（MyScript
  手写识别引擎服务，独立于既有录音双服务）。
- **Provider**：1→2→3——1.0.1 仅 WidgetImageProvider；1.0.3 新增
  ExportFileProvider（替换 FileProvider，817 登记）；1.4.2 新增
  ApiGatedFirebaseInitProvider（818 登记的 Firebase 门禁初始化）。

## Harmony 映射

- 5 widget provider → `noteformability` + RecentNotes/NoteThumbnail/
  FolderNotes FormFeed 数据源；LOCALE_CHANGED 由系统卡片重渲染承载。
- 录音双服务 → `AUDIO_RECORDING` 连续任务。
- HwrEngineService → `OriginalHandwritingRecognitionContextAdapter`。
- Provider 的 content-URI 共享 → formBinding/fd-share 等价。
- AppUpgradeReceiver → DB_VERSION 阶梯迁移器 + 启动链。
- ApiGatedFirebaseInitProvider → fail-closed（Firebase 域）。

## 交付物

- 证据：`docs/migration/evidence/phase-824-component-inventory.md`
- ADR：`docs/migration/adr/ADR-0768-component-inventory.md`
- Replay：`docs/migration/replays/d02-component-inventory.mjs`（7 项断言）

## 验证

- 新增 Replay：7/7 一次通过。
- 全量 Desktop Replay、双 HAP 构建随本 Phase 完成。

## 下一步

manifest 组件明细闭合（与 Phase 800 计数层互为明细/汇总）。
候选轴：`<activity>` 属性级明细（launchMode/configChanges/
windowSoftInputMode）、uses-permission 逐项、或 baseline.prof 抽样。
