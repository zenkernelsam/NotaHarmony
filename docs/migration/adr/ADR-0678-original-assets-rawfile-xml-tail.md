# ADR-0678 assets/+res/raw+res/xml 尾部收口登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：730
- 证据：`docs/migration/evidence/original-assets-rawfile-xml-tail-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-assets-rawfile-xml-tail.mjs`
- 接续：ADR-0675（font/assets 首段）、ADR-0676（drawable 族）、
  ADR-0677（manifest 组件）

## 背景

资源审计末段：APK `assets/` 154 项 + `res/raw` 10 项 + `res/xml`
10 项逐项归属核对。

## 决策

### 移植/功能等价（已就位）

- `app_widgets__*_widget_info.xml` ×5 → `forms_config.json`（Phase 726）。
- `filepaths.xml` FileProvider 路径 → fileUri+系统分享机制等价
  （Phase 729）。
- `emojis_unicode.json` → emoji 搜索框差异登记（文件夹 emoji 证据
  `original-folder-emoji-picker-harmony-2026-09-22.md`；策划子集
  网格已移植）。

### 边界登记（不移植）

| 资产 | 边界 |
|---|---|
| `conf/`、`conf-lite/`、`glmath/`、`resources/*.res` | MyScript HWR/数学识别引擎内部资源（引擎本体即边界，ADR-0670 HWR 面）。 |
| `mlkit-google-ocr-models/` ≈60 模型 | 内嵌 gocr OCR——MLKit/GMS 边界（docscan ADR-0647、PdfPageOcr 旗标）。 |
| `ConversionRates.csv` | Play Billing 价格→USD 归因换算（`sq2`/`rm0`/`j6b`，Singular 分析管道）——计费/分析边界（ADR-0662）。 |
| `NoteAsset*Worker`/`NoteAssetDatabase` | 笔记资产云同步 WorkManager/Room——后端同步边界。 |
| `ayp_youtube_player.html` | YouTube 内嵌播放器壳——YouTube 边界（ADR-0651 族）。 |
| `inky_2026_v32.riv`、`anim_{grow,learn,memorize,productivity}.riv`、`learn_confetti.riv` | Inky/Learn Rive 动效——ADR-0656/0652/0658 边界。 |
| `pdfnet.res`、`pdftron_*.plugin` | PDFTron 引擎内部件——Phase 727 登记。 |
| `core_remoteconfig__remote_config_defaults.xml` | 52 项旗标默认值=ac4 注册表工件——旗标语义 ADR-0658 已审计；文件为 Firebase 载体→边界。 |
| `splits0.xml`、`PublicSuffixDatabase.list`、`dexopt/baseline.prof*`、`m3_*` | Play 分发/OkHttp/profileinstaller/M3 平台件。 |

## 后果

原版 `res/`、`assets/`、`AndroidManifest.xml` 三大资源域审计
至此全部闭合：所有资源键落桶为已移植/程序化等价/文本化惯例/
功能等价/边界登记之一。后续审计主线转入 JADX `defpackage` 逻辑面
长尾（按需按特征逐面取证）。
