# 原版 values 资源尾项审计证据（JADX，decompiled_1.0.3）

证据日期：2026-09-25
证据来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\resources\res`

至此 strings/plurals/colors/fonts/drawables/mipmap/layout/raw/xml/
manifest 各资源面均已关闭（Phase 700–732）。本页补齐 `values*`
目录族最后一个面：arrays / bools / integers / dimens / styles /
attrs / public / drawables.xml 及各限定符目录。

## 目录盘点

`values/`：`arrays.xml`、`attrs.xml`(3854 行)、`bools.xml`、
`colors.xml`、`dimens.xml`(248 行)、`drawables.xml`、`integers.xml`、
`plurals.xml`、`public.xml`、`strings.xml`、`styles.xml`(1075 行)。

限定符目录：`values-h360dp-land`、`values-h480dp-land`、
`values-h720dp`、`values-land`、`values-large`（均仅 dimens）、
`values-ldrtl`、`values-nodpi`（drawables 别名）、`values-night`、
`values-night-v33`（styles）。

## 逐项分类

### 1. 已移植 / 已对齐

| 资源 | 原版值 | Harmony 对应 |
| --- | --- | --- |
| `app_widgets__widget_thumb_corner_radius` | 6dp | Phase 726 缩略图圆角 6dp |
| `app_widgets__widget_*` 色/形 | colors.xml 昼 + values-night 夜 | Phase 726/732 已入册 |
| `NightAdjusted.Theme.Nb`（values-night `Theme.Material.NoActionBar`） | 应用级夜主题 + `isLightTheme=false` splash + `windowLightStatusBar/NavigationBar=false` | `ThemeStore.setSystemDark` + `onConfigurationUpdate` + 持久化 mode（NoteAbility.ets:25-70） |
| `Theme.Nb`/`AppTheme`/`AppBaseTheme`/`Theme.Empty`/`Theme.Hidden` | 窗口主题链 | ArkUI 页面级自管背景 + ThemeStore |
| `Theme.Nb.Splash`/`app_widgets__ThemeSplash`（`postSplashScreenTheme`） | 启动 splash 窗口 | Harmony `start_window_background` + LaunchPage |
| `RobotoMedium`/`RobotoRegular` TextAppearance | Roboto 字重 | Phase 727 字体注册 + familyName 映射 |

### 2. SPen 边界（ADR-0671 / Phase 724 登记）

- `arrays.xml` 71 项中 **67 项为 `spen_setting_swatch_*` /
  `spen_setting_swatch_adaptive_*`**（SpenColorSwatchUtil 调色板），
  另有 `spen_adaptive_dark/light/standard_color` 3 项 —— Samsung
  SPen SDK 资源。
- `feature_note__quick_tool_center_size=96dp` /
  `quick_tool_edge_size=44dp`：`wod.java` 中喂给
  `SpenSettingQTLayout`/`SpenSettingQTColorDialLayout` —— Quick
  Tools 调色盘几何，SPen 边界。
- `setting_qt_opacity_angle_start/end`（integers 290/70）、
  `SettingQTCurvedHandlerTextStyle` —— 同上。

### 3. 平台/库边界

- `integers.xml` 23 项全部库内部：`abc_config_*`、
  `mtrl_*`/`m3c_*` 动画常量、`google_play_services_version`、
  `dialog_width_percentage`/`dim_dark`/`dim_light`/
  `hide_password_duration`（Samsung IAP `BaseDialog` 引用）。
- `bools.xml`：`workmanager_test_configuration`、
  `enable_system_*_service_default`（WorkManager）、
  `firebase_*_collection_*` —— GMS/遥测边界。
- `feature_learn__chat_card_headers`（arrays 唯一非 SPen 应用项）
  —— Learn 面边界（ADR-0651 系列）。
- `styles.xml` 其余 ~90% 为 M3/AndroidX/Sesl/PlayCore/浏览器菜单
  内部样式；`Theme.PlayCore.Transparent` 随 Play 边界。
- `values-land/integers.xml` 仅 `mtrl_calendar_header_orientation`；
  `values-ldrtl`/`values-nodpi` 仅 Material 箭头别名；
  `h360dp-land`/`h480dp-land`/`h720dp`/`large` dimens 全为
  Material/Preference 内部 —— 限定符目录无应用语义项。
- `attrs.xml` 3854 行：几乎全为库 `declare-styleable`（编译期
  类型声明，无运行期资源语义）。
- `public.xml`：aapt public-ID 固定表，构建产物无行为语义。
- `drawables.xml`：少量 `<drawable>` 别名桩。

### 4. 对话框窗口服饰（结构等价）

`DialogButton`/`DialogWindowTheme`/`FloatingDialogWindowTheme`/
`Theme.DialogTransparent`：Android 窗口属性附着（半透明、浮窗、
按钮条样式）。Harmony 对话框/半模态由 `CustomDialogController`/
`bindSheet` 系统样式承担，属结构性映射而非逐属性移植；各对话框
文案/按钮/圆角已在对应阶段逐件对齐。

## 涉及原版符号

`wod`（SpenSettingQTLayout 宿主）、`com.samsung.android.sdk.pen.
setting.quicktool.*`、`com.samsung.android.sdk.iap.lib.dialog.
BaseDialog`、`NightAdjusted.Theme.Nb`、`Theme.Nb.Splash`。

## 未验证声明

- 各限定符目录的 Material 内部值未逐项回链消费点（库内部常量，
  对应用行为无影响）。
- `attrs.xml` 应用自定义 attr 未逐一登记 —— 对应自定义 View
  本体若未移植，其 attr 无独立语义；已移植的自定义绘制（画布、
  纸纹）均以构造参数而非资源 attr 传入。
