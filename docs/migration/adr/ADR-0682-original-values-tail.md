# ADR-0682: 原版 values 资源族尾项收口（arrays/bools/integers/dimens/styles/attrs/public）

- 状态：已接受（收口登记）
- 日期：2026-09-25
- 阶段：Phase 734
- 证据：`docs/migration/evidence/original-values-tail-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-values-tail.mjs`

## 背景

strings/plurals/colors/fonts/drawable/mipmap/layout/raw/xml/manifest
各资源域已在此前阶段逐一关闭。`values*.xml` 目录族尚余
arrays/bools/integers/dimens/styles/attrs/public/drawables.xml 及
限定符目录未整体登记。本 ADR 完成该域收口审计。

## 分类决策

1. **已移植/已对齐**（无需新动作）：
   `widget_thumb_corner_radius`（Phase 726）、`app_widgets__` 色板
   昼/夜（Phase 726/732）、`NightAdjusted.Theme.Nb` 夜主题链 ↔
   Harmony `ThemeStore.setSystemDark` + `onConfigurationUpdate`
   （NoteAbility）、`Theme.Nb.Splash`/`app_widgets__ThemeSplash` ↔
   `start_window_background` + LaunchPage、Roboto TextAppearance ↔
   Phase 727 字体注册。
2. **SPen 边界**（ADR-0671/Phase 724 已登记）：67 个
   `spen_setting_swatch*` 数组、`spen_adaptive_*` 色数组、
   `setting_qt_opacity_angle_*` 整数、`quick_tool_center/edge_size`
   （`wod` → `SpenSettingQTLayout` 调色盘几何）、
   `SettingQTCurvedHandlerTextStyle`。
3. **平台/库边界**：integers/bools 全部为 AndroidX/Material/Play/
   WorkManager/Firebase/Samsung-IAP 内部常量；`feature_learn__*`
   数组随 Learn 面边界；styles 其余条目为库内部样式；
   `Theme.PlayCore.Transparent` 随 Play 边界。
4. **结构等价**：`DialogWindowTheme`/`FloatingDialogWindowTheme`/
   `Theme.DialogTransparent`/`DialogButton` 为 Android 窗口服饰
   机制；Harmony 以 `CustomDialogController`/`bindSheet` 系统样式
   承担，各对话框语义已逐件对齐。
5. **无运行期语义**：`attrs.xml`（declare-styleable 编译期声明）、
   `public.xml`（aapt ID 固定表）、`drawables.xml` 别名桩、全部
   限定符目录（仅 Material 内部值）。

## 结论

`res/values*` 域无未登记的便携行为项；剩余全部归属上述五类。
至此原版资源域（strings/plurals/colors/fonts/drawable/mipmap/
anim/layout/raw/xml/values*/manifest）审计全部关闭，后续审计向量
转向代码逻辑面（defpackage 尾项）。

## 边界与限制

- 限定符目录（land/h720dp/large/ldrtl/nodpi/night-v33）仅含
  Material 内部常量，未逐项回链消费点。
- `attrs.xml` 中应用自定义 attr 的语义依附于自定义 View 本体；
  未移植 View 的 attr 不具独立行为。
- 未做模拟器/真机/Hypium 验证。
