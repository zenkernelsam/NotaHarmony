# 原版 assets/+res/raw+res/xml 尾部证据（decompiled_1.0.3）

日期：2026-09-25。范围：APK `assets/`（154 项）、`res/raw/`（10 项）、
`res/xml/`（10 项）。

## assets/ 分桶

| 资产 | 归属 |
|---|---|
| `conf/*.conf`、`conf-lite/`（6） | MyScript HWR 引擎语法配置（diagram/math2/raw-content2/shape/en_US）——HWR 引擎边界（ADR-0670 HWR 面注册）。 |
| `glmath/`（≈30 ttf+xml） | MyScript 数学字形库（cmex/cmmi/euler/latin/cyrillic 字族 + 符号映射）——同上引擎内部件。 |
| `resources/*.res`（en_US-ak-cur/lk-text/math-sr/shk-diagram/dl-raw-content/ank-diagram 等 10） | MyScript 识别模型资源——同上。 |
| `mlkit-google-ocr-models/`（≈60 tflite/fb/binarypb） | 内嵌 gocr OCR 模型——MLKit/GMS 边界（ADR-0647 docscan、`androidPdfPageOcr` 旗标族）。 |
| `emojis_unicode.json` | emoji 名称语料（`u22`/`n` 搜索索引）——搜索框未移植已在文件夹 emoji 证据登记（`original-folder-emoji-picker-harmony-2026-09-22.md` 差异节）。 |
| `ConversionRates.csv` | `sq2.a(code, micros/1e6)` 货币换算表（9/1/24 USD 基准）——`rm0`/`j6b` 消费方为 Play Billing 价格→USD 的归因上报（Singular），计费/分析边界（ADR-0662）。 |
| `NoteAssetDatabase*`,`NoteAsset{Download,Transfer,Upload}Worker` | 笔记资产云同步 Room/WorkManager——后端同步边界。 |
| `PublicSuffixDatabase.list` | OkHttp 内部域名单——平台件。 |
| `dexopt/baseline.prof{,m}` | androidx.profileinstaller 基线 profile——平台件（Phase 729 AppUpgradeReceiver 同族）。 |
| `resources/analyzer`/`document_layout`/`shape`/`math`/`en_US` | 并入 MyScript 桶（`.res` 模型）。 |

## res/raw/ 分桶

| 资产 | 归属 |
|---|---|
| `ayp_youtube_player.html` | YouTube 内嵌播放器壳——YouTube 转录/导入边界（ADR-0651 族）。 |
| `feature_note_inky__inky_2026_v32.riv` | Inky 吉祥物 Rive——Phase 708 fail-closed（ADR-0656）。 |
| `ui_designsystem__anim_{grow,learn,memorize,productivity}.riv` + `learn_confetti.riv` | Learn 模式 Rive 动效——Learn 旗标域边界（ADR-0652/0658）+ Phase 727 资产登记。 |
| `pdfnet.res` + `pdftron_{exotic_font,layout,smart_substitution}.plugin` | PDFTron 引擎内部资源——PDFTron 边界（Phase 727 登记）。 |

## res/xml/ 分桶

| 文件 | 归属 |
|---|---|
| `app_widgets__*_widget_info.xml`（5） | widget 元数据（预览图/尺寸/类别/可配置）——已映射 `forms_config.json`（Phase 726）。 |
| `filepaths.xml` | FileProvider 路径声明——Harmony 无 FileProvider（Phase 729 功能等价登记）。 |
| `core_remoteconfig__remote_config_defaults.xml` | Firebase Remote Config 52 项默认值——`ac4` 70 旗标注册表的离线默认载体，ADR-0658 已系统审计旗标语义；文件本身为旗标系统工件→边界。 |
| `splits0.xml` | App Bundle 拆分元数据（Play 分发工件）→平台边界。 |
| `m3_button_group_child_size_change.xml` | Material3 内部资源→平台边界。 |

## 结论

`assets/`+`res/raw`+`res/xml` 全部项有归属：移植（widget_info→forms
_config）、功能等价（filepaths→fileUri 机制）、登记差异（emoji
语料/搜索框）、边界（MyScript/MLKit/PDFTron/YouTube/Inky/Learn/
同步 workers/计费分析/平台件）。至此原版 `res/`、`assets/`、
AndroidManifest 三大资源域审计全部闭合。
