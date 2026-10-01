# Phase 1438 报告 — 叶子轴末扫收口

## 概述

本阶段对 `decompiled_1.4.2` 全树做穷尽式叶子末扫，确认"未判定且可移植"的轴
已全部清空；对末扫中最后核验的 8 个叶子/族给出终局裁决并成文。

## 裁决结果

| 轴 | 结论 |
|----|------|
| `ui_fileimport__*`（43 键） | 已移植（`ImportDetailsSheet` + `import_*` 全套） |
| `feature_settings__*` 可移植编辑器段 | 已移植（`EditorSettingsStore` + `keepScreenOnApplied` 等） |
| `ui_text__*`（90 键） | 已移植（`OriginalKeyboardChords` + Prism4j + 样式表面） |
| `feature_note__text_only_*` + `isTextOnly` + `grb` | 已移植（`saveIsTextOnly` + 菜单信号 + 流式排版） |
| `spen_setting_swatch_*` / `spen_adaptive_*` 数组 | vendored（三星 S-Pen SDK 内部资源） |
| `data/` 后端 worker 族 | fail-closed（复核此前裁决） |
| `app/resume` + Receiver + Provider 族 | 平台/后端边界（复核此前裁决） |
| XAPK split 轴 | P1433 已裁决 |

## 关键核验

- **`isTextOnly` 全链路**：`NoteRepositoryImpl.ets:991` 已有 `saveIsTextOnly`
  （对应 `xf3.java:103` 专属 UPDATE）；`NotePage` 含 `textOnlySignal`/
  `textOnlyExitSignal`/`textOnlyActive` 三信号；`NoteCanvasView.ets:274`
  含 `grb.TextOnly` 流式排版参数。远程旗标 `androidTextOnlyMode` 默认 `false`，
  但本地实现已完整落地，归入"已移植"而非旗标 fail-closed。
- **三星调色板**：`spen_*` 数组的消费者全部位于
  `com.samsung.android.sdk.pen.setting.color.*`（`SpenColorPaletteUtil`/
  `SpenSettingUtilColor`/`SpenReverseColorTheme`），属 SDK 自带资源，
  与 `config.arm64_v8a` 的 `libSPenBase` 同一边界。
- **settings 编辑器段**：`keep_device_awake`→`keepScreenOnApplied` +
  `keepAwakeGeneration`（`NotePage`），`auto_deselect_eraser`→
  `EditorSettingsStore`（注释明引 `o59.c` 真值表）。
- **文件导入 43 键**：`import_dest_*`/`import_pdf_password_*`/`import_arrange`/
  `import_move_*`/`partial_import` 等全套落位。

## 验证

- Replay：`d02-leaf-sweep-terminal-closure.mjs` 10/10 全绿。
- 全量基线：1288/1288（+1 fixture）。
- `note@default`、`note@ohosTest` HAP 构建均通过（仅有既知签名告警）。

## 文档

- 证据：`docs/migration/evidence/phase-1438-leaf-sweep-terminal.md`
- ADR：`docs/migration/adr/ADR-1373-leaf-sweep-terminal.md`
- Replay：`docs/migration/replays/d02-leaf-sweep-terminal-closure.mjs`
