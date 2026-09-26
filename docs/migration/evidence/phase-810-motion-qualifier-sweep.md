# Phase 810 — 动画/选择器资源面与限定符资源收敛(res/ 树闭合)

## 目的

继 strings(ADR-0749)、arrays(ADR-0752)、plurals(ADR-0753)、
font/raw/xml/drawable/layout 各面登记后，`res/` 树剩余未逐类对比的
目录为 `anim/`、`animator/`、`color/`、`interpolator/`(运动/着色/选择器
资源)以及全部 `values-*` 限定符目录。本阶段完成该残余面取证,
实现 `res/` 整树收敛。

## 取证路径

- `decompiled_{1.0.3,1.4.2}/resources/res/{anim,animator,color,interpolator}/`
- `decompiled_{1.0.3,1.4.2}/resources/res/values-*/`

## 运动/着色资源对比

| 目录 | 1.0.3 | 1.4.2 | 移除项性质 |
|---|---|---|---|
| anim | 19 | 15 | 4 项全为 `abc_*` AppCompat 弹窗动画 |
| animator | 9 | 7 | 2 项全为 `mtrl_*` 按钮/Chip 状态动画 |
| color | 32 | 10 | 22 项全为 `abc_*`/`design_*`/`material_*` 厂商着色 |
| interpolator | 7 | 7 | 零移除 |

移除全部为厂商库(View 体系)资源，与 Phase 791/809 的 Compose 化
裁剪结论一致 —— 1.4.2 进一步剔除 AppCompat/Material 的运行时资源,
无语义损失。

## 存留项核查(1.4.2)

- `anim/`、`animator/`、`interpolator/` 存留 = Material checkbox/radio
  内置动画 + fragment 转场 + **`spen_recoil_*` 三项应用级资源**:
  `spen_recoil_pressed_scale_interpolator`、
  `spen_recoil_released_scale_interpolator`、
  `spen_recoil_button_selector` —— 笔设置按钮的按压回弹微动画,
  **两版均存,非差异**(SPen 交互面,此前 phase 已登记 SPen 体系)。
- `color/` 存留 10 项 = AppCompat/GMS SignIn 按钮着色 + 应用
  `dialog_button_text_color`,两版一致。

## values-* 限定符目录全量扫描

对 12 个限定符目录(hdpi/night/night-v33/nodpi/v33/v34/w1920dp/
w480dp/w600dp/w960dp/watch/xxhdpi)逐一扫描
`colors|dimens|bools|integers|strings|styles` 中引用
`feature_|ui_|app_|pen_` 命名前缀的应用级条目:

- **应用级条目数两版逐文件相等** —— 所有限定符目录的应用差异为零。
- `values-night/colors.xml` 两版逐字节一致(widget/shortcut/
  mini-setting 暗色,18 项应用色)。
- `values-watch/` 等为厂商表盘样式,无应用内容。

## 目录级限定符重构(版本差异)

`res/` 顶层子目录存在版本差异，但逐一核查后全部为厂商内容：

**移除 15 个目录**(均含零应用级条目，纯 AppCompat/Material/
fragment 变体桶):

- `color-night`、`layout-land`、`layout-watch`
- `values-h360dp-land`、`values-h480dp-land`、`values-h720dp`、
  `values-land`、`values-large`、`values-ldrtl`、`values-sw600dp`、
  `values-w320dp-land`、`values-w360dp-port`、`values-w400dp-port`、
  `values-w600dp-land`、`values-xlarge`

**新增 2 个目录**:`drawable-hdpi`、`values-hdpi`。(v33/v34/
w1920dp/watch/night-v33/nodpi/xxhdpi 等限定符桶在 1.0.3 已存在。)

性质：View 时代的屏幕尺寸/朝向/RTL 桶在 Compose 化后被废弃
(Compose 在代码层处理自适应),改由 API 级(v33/v34)、密度级
(hdpi/nodpi/xxhdpi)、手表与超宽(w1920dp,折叠屏)桶替代。
该重构是厂商资源打包行为，不含应用文案/语义。

## 结论

`res/` 树至此**全目录收敛**:动画/着色/插值器的版本差异全为厂商裁剪;
唯一应用级运动资源 `spen_recoil_*` 两版共存(SPen 按压微动画);
限定符目录的应用级差异为零，目录级增删为 View→Compose 时代的
厂商限定符重构。整个 `res/` 目录树的版本差异面登记完毕。
