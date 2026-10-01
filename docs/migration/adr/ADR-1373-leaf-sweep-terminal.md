# ADR-1373 叶子轴末扫收口（terminal leaf-sweep closure）

## 状态

Accepted — 2026-08-16（Phase 1438）

## 背景

自 Phase 1 起逐轴推进 `decompiled_1.4.2` → HarmonyOS 移植，各资源族与包叶子
分别在不同 Phase 完成移植或裁决。本阶段执行一次**穷尽式叶子末扫**，确认不再有
"未判定且可移植"的轴残留，并把末扫中最后核验的 8 项落档。

## 决策

对 `decompiled_1.4.2` 全树（`res/values*`、`res/xml`、`res/font`、`assets/`、
`resources/`、`META-INF/`、`kotlin/`、`firebase/`、`google/`、
`com.gingerlabs.*` 全叶子包、`com.samsung`/`com.myscript`/`com.google.*`/
`androidx.*` vendored 树、Activity/Service/Receiver/Provider/Application/
WorkManager entry-point、XAPK split）做末扫，结论：

- **已移植**（本阶段核验确认）：
  - `ui_fileimport__*` 43 键 → `ImportDetailsSheet` + `import_*` 字符串全套
  - `feature_settings__*` 可移植编辑器段 → `EditorSettingsStore` +
    `keepScreenOnApplied`/`keepAwakeGeneration` + `SettingsPage`/`PageSettingsPanel`
  - `ui_text__*` 90 键 → `OriginalKeyboardChords` + `CodeSyntaxHighlighter`
    （Prism4j）+ `buildCodeLanguageMenu` + 文本样式/对齐表面
  - `feature_note__text_only_*` + `isTextOnly` + `grb` → `saveIsTextOnly`
    （`xf3` 专属 UPDATE 对应物，`NoteRepositoryImpl.ets:991`）+
    `textOnlySignal`/`textOnlyExitSignal`/`textOnlyActive` +
    `NoteCanvasView` 流式排版；远程旗标 `androidTextOnlyMode` 默认 `false`，
    但 Harmony 已落成完整本地路径，属"已移植"而非旗标 fail-closed
- **vendored 边界**（本阶段核验确认）：
  - `spen_setting_swatch_1..23` / `spen_adaptive_{light,dark,standard}_color`
    数组 → `com.samsung.android.sdk.pen.setting.color.*` 三星 SDK 自带资源，
    与 `config.arm64_v8a` 中 `libSPenBase` 同一边界（P1433 已裁决该 ABI 层）
- **后端/硬件/平台边界 fail-closed**（复核此前裁决）：
  - `data/` 同步/上传/下载 worker 族、`app/resume`、`AppUpgradeReceiver`、
    `MissingNativeLibraryActivity`、`FileProvider`、Zendesk `ui/support`、
    `DemoResetWorker`、转写/订阅/配额链路 — 维持此前各 ADR 结论
- **XAPK split 轴** — P1433 已完整裁决

## 理由

1. `decompiled_1.4.2` 树经逐族、逐包、逐 entry-point 枚举，叶子集合已封闭；
   剩余项均落入四类之一，不存在第五类"未判定"。
2. 对仍 default-off 的生产远程面（如 `androidTextOnlyMode`），Harmony 侧
   已有完整本地实现且持久化无损（`isTextOnly` 列 + 专属 UPDATE + 流式排版 +
   自动退出信号），不再按 ADR-0746 的"伪远程旗标"情形处理——该 ADR 针对的是
   "无本地实现却虚构旗标"的情形，此处实现已存在。
3. 三星 S-Pen SDK 资源（swatch/adaptive palette）属 vendored SDK 内部常量，
   其调色板从未进入原版应用层 UI（消费者全部在 `com.samsung.*` 包内），
   不值得引入；与 `config.arm64_v8a` 的 `libSPenBase` 同一边界。

## 后果

- 静态移植面在叶子层级封闭；后续 Phase 转向组合场景回归、跨 Phase 衔接复核，
  以及（最终项）T-042 版本追踪。
- 本 ADR 为末扫成文，不新增行为变更；任何后续发现的漏项按既有
  "evidence → ADR → Replay → 报告"流程单独立 Phase。

## 证据

- `docs/migration/evidence/phase-1438-leaf-sweep-terminal.md`
- Replay：`d02-leaf-sweep-terminal-closure.mjs`（10/10）
- 关联：ADR-0746（default-off 远程旗标 fail-closed 原则）、ADR-0652（转写）、
  ADR-0786/0662（订阅/配额）、ADR-0719/0767（零售演示）、P1433（split 轴）、
  P1435（`cs0` 维护编排 + 内存压力修剪）
