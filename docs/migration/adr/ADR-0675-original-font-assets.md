# ADR-0675 font/ + assets/ 资源族收口：编辑器三族字体内置 + 资产边界登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：727
- 证据：`docs/migration/evidence/original-font-assets-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-font-assets.mjs`

## 背景

非字符串资源审计最后两族：`res/font/`（13 个字库文件）与
`assets/`（PDFTron 引擎资源、Rive 动效、YouTube 播放器模板）。

`qr4.java` 静态段揭示原版文本字体族选择器为三族：
`zq8("Inter")`（缺省，`b = zq8Var`）、`zq8("Roboto")`、
`zq8("EBGaramond")`——每族经 `kr4` 装载 regular 变量字 + bold +
italic 变体。Harmony 选择器三族名称/写库字段早已对齐
（`familyName` 序列化），但字库文件未内置，Canvas2DTextRenderer
发出的 `"Inter"` 等 familyName 只能落系统回退，字形不一致。

## 决策

### 已移植

- 三族 regular 变量字库拷入 `resources/rawfile/fonts/`
  （inter.ttf / roboto.ttf / ebgaramond.ttf，OFL/Apache-2.0 开源
  许可，允许再分发）；`NoteFonts.registerNoteFonts(uiContext)`
  经 `UIContext.getFont().registerFont` 注册三族到窗口字体表，
  `TextBlockOverlay.aboutToAppear` 与 `NoteCanvasView.aboutToAppear`
  各挂一次（模块级幂等守卫）。
- 变量字含 wght 轴 → 加粗字重随变量轴解析。

### 记录差异

- 原版每族另载专用 bold/italic 文件（kr4 三元组）；Harmony
  `FontOptions` 一族一源，斜体由渲染器对注册族合成 oblique——
  EBGaramond 等真斜体字形差异登记于此（视觉近似，非逐形）。
- `qr4.g` 旧族名映射（NotoSerif/NotoSansMono/CutiveMono/
  DancingScript/ComingSoon/CarroisGothicSC → 显示名）：仅为历史
  笔记 familyName 的展示别名表；Harmony 选择器按现三族展示，
  旧名笔记照常以 familyName 字段存储/渲染回退——语义保留，
  展示别名差异登记。

### 边界登记（不移植）

- `gtamericamono_bold.otf`、`gtflairebasic_black/extra.otf`、
  `proximasoft_bold/medium/regular.otf`、`untitledserif_*.otf`
  （8 个商业许可字库）：均为付费墙/品牌/upsell 面用字
  （`feature_settings__upsell_illustration.webp` 同簇），相关面已
  fail-closed（ADR-0662）；商业许可不随 APK 再分发。
- `assets/pdfnet.res`、`pdftron_exotic_font_resources.plugin`、
  `pdftron_layout_resources.plugin`、`pdftron_smart_substitution.plugin`：
  PDFTron 引擎私有资源——Harmony 走 PDFKit 渲染管（既有 PDF 导入/
  背景管线的引擎差异，ADR 群已记录引擎边界）。
- `assets/feature_note_inky__inky_2026_v32.riv`：Inky 吉祥物 Rive
  动效——ADR-0656 已 fail-closed。
- `assets/ui_designsystem__anim_{grow,learn,memorize,productivity}.riv`
  + `learn_confetti.riv`：Learn/ onboarding 庆祝动效——Learn 面与
  Rive 运行时边界（ADR-0652；HarmonyOS 无 Rive 运行时已内置）。
- `assets/ayp_youtube_player.html`：YouTube 转录导入的 iframe
  播放器模板——youtube_* 面已 fail-closed（ADR-0651/0670）。

## 后果

- 文本编辑 Inter/Roboto/EBGaramond 渲染命中真实字形（含变量字重），
  与原版选择器语义闭环。
- `res/font/`、`assets/` 两族全键归档；非字符串资源审计至此全闭
  （strings/plurals/arrays/bools/integers/dimens/colors/styles/font/
  assets/layout/xml 均已有归属）。
