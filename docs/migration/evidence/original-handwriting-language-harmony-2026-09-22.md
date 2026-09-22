# 原版手写识别语言设置 → Harmony 移植证据（Phase 567）

日期：2026-09-22
来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`（只读证据）

## 原版现场

### 设置行（x22.java case 5）

`sources/defpackage/x22.java` 的 Handwriting & Drawing 子区按序渲染：

| case | 字符串资源 | 说明 |
|------|-----------|------|
| 0 | `feature_settings__straight_lines` | Phase 565 已移植 |
| 1 | `feature_settings__shapes_detection` | 已移植 |
| 2 | `feature_settings__palm_detection` | Phase 564 已移植 |
| 3 | `feature_settings__auto_deselect_eraser` | Phase 563 已移植 |
| 4 | `feature_settings__ruler_units` | **未移植**：Harmony 无尺具 |
| 5 | `feature_settings__language` | 本 Phase |

行标签：`feature_settings__language` → "Language"。
说明文案：`feature_settings__handwriting_language_is_used_to_improve_recognition_and_search_of_your_handwritten_notes`
→ "Handwriting language is used to improve recognition and search of your
handwritten notes."（strings.xml:757）

### 当前语言显示（pb5.java case 0）

`pb5.java:56-58`：行尾以 `uy7.b0(dc5Var, map)` 渲染当前语言的显示名——
map 为 `dc5 → 显示名` 映射；`ub5` UiState 的 `f` 字段即当前 `dc5`。

### 语言枚举与默认值（dc5.java / ub5.java）

`dc5` 共 23 项，构造参数 `(localeCode, languageTag)`：
`de_DE/de, en_US/en, es_ES/es, fr_FR/fr, it_IT/it, ja_JP/ja, ko_KR/ko,
nl_NL/nl, no_NO/nb, pt_BR/pt, ru_RU/ru, tr_TR/tr, zh_CN/zh-Hans,
zh_TW/zh-Hant, th_TH/th, fil_PH/fil, id_ID/id, ms_MY/ms, pl_PL/pl,
sv_SE/sv, uk_UA/uk, vi_VN/vi, da_DK/da`。
`ub5()` 默认 `recognitionLanguage = dc5.L`（= en_US 系）。

### 选择器与持久化

- `vmc.java`：语言选择器 ViewModel（每语言可查可用性 `f.b(dc5)`，
  选择写全局偏好）。
- `gg1.f(dc5)`：显示名来自语言包元数据——内置包走 `f5j.c`（assets/conf
  zip 路径），已安装包走 `boh.c(file)` 读取包内名称。
- 全局偏好持久化 `dc5.I`（localeCode），由 `kc5/fr2` 路径读写；识别管线
  `jc5.e` 按 note → 全局偏好 → 系统 locale → en_US 解析。

## Harmony 现状（移植前）

`OriginalHandwritingLanguagePolicy.ets` 已完整移植 dc5 枚举顺序、
`resolveOriginalHandwritingLanguage`（note → global → system → en_US）
与 `readHarmonyOriginalHandwritingLocale` 适配器；
`OriginalHandwritingLanguagePreferenceStore` 已按 mutex + 事务 + 回滚
持久化 `recognitionLanguageId`（localeCode）。**缺设置页 UI**：无任何
`ui/` 文件引用该 store。

## Harmony 落地

- `OriginalHandwritingLanguagePolicy.ets`：为每个 dc5 定义补 `displayName`
  （MyScript 语言包原生名）；导出 `originalHandwritingRecognitionLanguageOptions()`
  与 `originalHandwritingLanguageDisplayName()`。
- `SettingsPage.ets`：
  - `reloadSettings` 经 `getRecognitionLanguageId()` 读全局偏好；未设置时
    按 `resolveOriginalHandwritingLanguage(null, stored, systemLocale)`
    解析出有效语言（与原版 `ub5.f` 显示当前语言的语义一致）。
  - Handwriting 块尾部新增 Language 行：`language` 标签 + 原版 caption +
    右侧当前语言显示名，点击打开选择器。
  - `HandwritingLanguageDialog`（@CustomDialog）：按 dc5 顺序列出 23 项，
    当前项打勾，点选即 `onPick` 并关闭。
  - `setRecognitionLanguage`：与既有设置同一乐观更新 + saveBusy 互斥 +
    lifecycleGeneration/处置守护 + 失败回滚 + `editor_setting_save_failed`
    toast；写 `saveRecognitionLanguageId(localeCode)`（store 内部规范化
    为 dc5.I localeCode）。

## 不可等价处（fail-closed）

- 原版的语言包**下载/可用性状态**（`vmc.f.b(dc5)`、`pm8.c` 下载管线）
  在 Harmony 侧不存在；本 Phase 仅移植“选择全局识别语言”的设置语义，
  23 项全部可选。已在 ADR-0538 记录。
- `ruler_units`（x22 case 4）因 Harmony 无尺具不移植。
- 原版行尾显示名取自语言包元数据；Harmony 使用随包原生名表（同 dc5
  顺序），内容等价、来源不同，已记录。

## 验证

- 新增 `docs/migration/replays/d02-original-handwriting-language.mjs`
  （26 断言：字符串、policy 表面、SettingsPage 接线、守护与回滚、行序、
  选择器结构）。
- 全量 Desktop Replay 见提交记录；`note@default`/`note@ohosTest` 构建
  BUILD SUCCESSFUL（仅既有未签名告警）。
