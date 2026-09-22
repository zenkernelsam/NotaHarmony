# ADR-0538：原版手写识别语言设置（feature_settings__language）

- 日期：2026-09-22
- 状态：已采纳（含 fail-closed 差异登记）

## 背景

原版 `x22.java` case 5 在 Handwriting & Drawing 子区渲染
`feature_settings__language` 行；`pb5.java` case 0 显示当前语言显示名
（`uy7.b0(dc5Var, map)`）；`vmc` 为 23 项 `dc5` 语言选择器，写入全局
偏好 `dc5.I`（localeCode），识别管线 `jc5.e` 按 note → 全局偏好 →
系统 locale → en_US 解析。

Harmony 侧 `OriginalHandwritingLanguagePolicy`（dc5 枚举/解析）与
`OriginalHandwritingLanguagePreferenceStore`（mutex 事务持久化）早已
移植并被识别上下文适配器消费，唯独缺设置入口——存储成了无写入来源的
死路径。

## 决策

在 SettingsPage 手写块尾部（auto_deselect_eraser 之后，对齐 x22 中
language 位于子区末尾的顺序；ruler_units 因无尺具跳过）新增 Language
行：标签 + 原版 caption + 右侧当前语言显示名，点击打开
`HandwritingLanguageDialog`（dc5 顺序 23 项、当前项打勾）。选中经
`setRecognitionLanguage` 走既有乐观更新 + 互斥 + 生命周期守护 + 失败
回滚模式，最终调 `saveRecognitionLanguageId(localeCode)`。

显示名：原版取自语言包元数据（`gg1.f`/`boh.c`/`f5j.c`），Harmony 在
policy 内随 dc5 定义保存同名原生显示名，通过
`originalHandwritingRecognitionLanguageOptions()` 供 UI 枚举。

未设置偏好时行尾显示有效语言：与原版 `ub5.f` 一致地解析
`resolveOriginalHandwritingLanguage(null, stored, systemLocale)`。

## 后果与差异登记

- 原版选择器带语言包下载/可用性状态（`vmc.f.b`、`pm8.c`）；Harmony 无
  语言包分发管线，23 项全部可选——fail-closed 差异，记于证据文档。
- `ruler_units`（x22 case 4）不移植：Harmony 无尺具功能。
- SettingsPage 仍是单 `note_editor` 头的扁平结构，未引入原版
  document_defaults/typing/handwriting/gestures 子区分节；本 Phase 只
  保持子区内部行序，分节结构差异维持现状登记。

## 验证

- `d02-original-handwriting-language.mjs` 26 断言通过；全量 replay 全绿。
- `note@default` 与 `note@ohosTest` assembleHap BUILD SUCCESSFUL。
