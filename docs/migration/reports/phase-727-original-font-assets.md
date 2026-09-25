# Phase 727 中文报告：font/ + assets/ 资源族收口

## 范围

`res/font/`（13 字库）与 `assets/`（PDFTron 资源/Rive 动效/YouTube
模板）——非字符串资源审计最后两族。

## 原版证据

见 `docs/migration/evidence/original-font-assets-jadx-2026-09-25.md`：

- `qr4.java` 静态段：文本字体族三选一（Inter 缺省 / Roboto /
  EB Garamond），每族装载 regular 变量字 + bold + italic 变体；
  `qr4.g` 为旧内置族名的展示别名表（NotoSerif 等 6 项）。
- `res/font/`：开源三族变量字（Inter/Roboto/EBGaramond，
  OFL/Apache-2.0）+ 8 个商业字库（GT America Mono/GT Flaire/
  ProximaSoft/Untitled Serif——upsell/品牌面用）。
- `assets/`：inky Rive、4+1 个 designsystem/Learn Rive、
  YouTube iframe 模板、PDFTron 引擎私有资源 4 件。

## 变更

- 拷入三族 regular 变量字库至 `resources/rawfile/fonts/`
  （inter/roboto/ebgaramond.ttf ≈2.2MB）。
- 新增 `NoteFonts.ets`：`registerNoteFonts(uiContext)` 幂等注册三族，
  `TextBlockOverlay`/`NoteCanvasView` `aboutToAppear` 各挂一次——
  Canvas2DTextRenderer 的 `"Inter"`/`"EBGaramond"` fontFamily 自此
  命中真实字形；变量 wght 轴覆盖字重。
- 斜体差异记录（原版载专用斜体文件，Harmony 一族一源走合成）。

## 边界登记（ADR-0675）

8 商业字库（许可 + upsell 边界）、PDFTron 4 件（PDFKit 引擎差异）、
inky/Learn Rive 6 件（ADR-0656/0652）、YouTube 播放器模板
（ADR-0651）。

## 验证

- `d02-original-font-assets.mjs` 全绿。
- 全量 Desktop Replay 全绿。
- `note@ohosTest` + `note@default` clean 构建成功，无新增 ArkTS 错误。
