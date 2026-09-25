# Phase 734 报告：values 资源族尾项收口

- 日期：2026-09-25
- 性质：收口登记（无代码改动）
- ADR：ADR-0682
- 证据：`original-values-tail-jadx-2026-09-25.md`
- Replay：`d02-original-values-tail.mjs`

## 背景

资源域审计此前已覆盖 strings/plurals/colors/fonts/drawable/mipmap/
anim/layout/raw/xml/manifest。本阶段补齐 `values*.xml` 目录族的
最后一个面：arrays、bools、integers、dimens、styles、attrs、
public、drawables.xml 及全部限定符目录（h360dp-land/h480dp-land/
h720dp/land/large/ldrtl/nodpi/night/night-v33）。

## 审计结果

| 桶 | 条目 | 处置 |
| --- | --- | --- |
| 已移植 | `widget_thumb_corner_radius`、widget 色板昼夜、`NightAdjusted.Theme.Nb`、splash 主题链、Roboto TextAppearance | Phase 726/727/732 + ThemeStore 既有机制 |
| SPen 边界 | 67×`spen_setting_swatch*`、3×`spen_adaptive_*`、`quick_tool_*_size`、`setting_qt_*`、`SettingQTCurvedHandlerTextStyle` | ADR-0671/Phase 724 既有登记 |
| 平台/库边界 | integers/bools 全量（WorkManager/Firebase/Material/Play/Samsung-IAP）、`feature_learn__chat_card_headers`、库样式 | 既有遥测/Learn/Play 边界 |
| 结构等价 | `DialogWindowTheme`/`FloatingDialogWindowTheme`/`Theme.DialogTransparent`/`DialogButton` | Harmony 系统对话框样式承担 |
| 无语义 | `attrs.xml`（编译期）、`public.xml`（ID 固定）、`drawables.xml` 别名、限定符目录（Material 内部） | 无需动作 |

## 关键确认

- 应用级夜主题原版以 `values-night/styles.xml` 的
  `NightAdjusted.Theme.Nb` + splash `isLightTheme=false` 实现；
  Harmony 侧 `NoteAbility.onConfigurationUpdate` →
  `ThemeStore.setSystemDark` + 持久化 mode 已等价（无需改动）。
- `feature_note__quick_tool_*` 经查 `wod.java` 喂给
  `SpenSettingQTLayout`/`SpenSettingQTColorDialLayout`，属 SPen
  Quick Tools 调色盘几何，非应用面板。
- 全部限定符目录仅含 Material 内部常量，无应用语义。

## 验证

- 专项 Replay：31 项断言全绿。
- 全量 Desktop Replay + 双 HAP 按协议复验（纯文档阶段）。

## 结论

`res/values*` 域关闭，原版资源域审计全部完成。下一阶段起审计
向量转向 `defpackage` 代码逻辑尾项。
