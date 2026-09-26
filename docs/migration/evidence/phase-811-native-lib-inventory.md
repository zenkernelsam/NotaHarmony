# Phase 811 — 原生 .so 库清单版本差

## 目的

META-INF 依赖清单(Phase 798)与 meta-data(Phase 801)已登记，但
`config.arm64_v8a.apk` 内的 `lib/arm64-v8a/*.so` 文件级清单尚未做
版本对比。本阶段钉住原生库层差异。

## 取证路径

- `Notability_1.0.3/Notability_+AI+Note+Workspace_1.0.3_APKPure.xapk`
  内嵌 `config.arm64_v8a.apk`
- `Notability_1.4.2/..._apkcombo.com.xapk` 内嵌 `config.arm64_v8a.apk`
- `arm64_extracted/`(已确认 = 1.0.3 提取,26 项逐名一致)

## 文件级差异

**计数 26 → 31;移除 0;新增 5:**

| 新增 .so | 归属 |
|---|---|
| `libcrashlytics.so` | Firebase Crashlytics NDK |
| `libcrashlytics-common.so` | Crashlytics NDK |
| `libcrashlytics-handler.so` | Crashlytics NDK |
| `libcrashlytics-trampoline.so` | Crashlytics NDK |
| `libzstd-jni-1.5.7-4.so` | zstd JNI(压缩) |

Crashlytics NDK 四件套与 Phase 801 manifest meta-data 增量
(`com.google.firebase.crashlytics.ndk.CrashlyticsNdkRegistrar`)互为
印证 —— 同一 1.4.2 新依赖在打包层与注册层各出现一次。
`libzstd-jni` 与 Phase 798 的 `zstd-jni` .version 条目互为印证。

## 大小增量(12 项，内容级升级)

| .so | 1.0.3 | 1.4.2 | Δ |
|---|---|---|---|
| librive-android | 5,268,128 | 6,010,104 | +14.1% — 与 808 的 Rive 256→485 文件升级互证 |
| libink | 1,316,520 | 1,415,664 | +7.5% — 与 798 ink-storage/778 nib 模型互证 |
| libiink | 24,642,176 | 25,906,560 | +5.1% — MyScript iink 引擎升级 |
| libMyScriptMLOrt | 10,210,616 | 10,598,960 | +3.8% |
| libMyScriptGesture | 533,448 | 541,736 | +1.6% |
| libMyScriptInk | 987,552 | 1,042,016 | +5.5% |
| libMyScriptDocument | 2,733,040 | 2,796,464 | +2.3% |
| libMyScriptEngine | 2,019,448 | 2,025,576 | +0.3% |
| libMyScriptText | 3,204,968 | 3,207,776 | +0.1% |
| libPDFNetC | 61,026,528 | 62,079,520 | +1.7% — PDFTron 升级 |
| libglmath | 2,737,792 | 2,801,072 | +2.3% |
| libandroidx.graphics.path | 10,096 | 9,952 | −1.4% |

其余 14 项(`libc++_shared`、`libicing`、`libmlkit_google_ocr_pipeline`、
`libsqliteJni`、`libtiff*`×4、`libdatastore_shared_counter`、
`libgraphics-core`、`libMyScript{2D,Analyzer,Math,Shape}`)大小不变。

## 未变化的关键库(语义稳定)

- `libicing` — AppSearch 引擎(Phase 785 的 AppSearch 面)
- `libmlkit_google_ocr_pipeline` — MLKit OCR 管线(Phase 802
  `androidImageBlockOcr` 旗标所控)
- `libsqliteJni`、`libtiff*` — SQLite/TIFF 基础设施
- `libMyScript{2D,Analyzer,Math,Shape}` — MyScript 其余模块

## Harmony 侧

Harmony HAP 为纯 ArkTS/ArkUI，无上述原生库依赖：
- MyScript/iink → 已由 Harmony 侧手写转换面替代(此前阶段登记)。
- PDFTron → Harmony 使用自研 PDF 渲染管线(早期 ADR 已登记)。
- Crashlytics NDK → 无原生崩溃报告通道,fail-closed。
- zstd → Harmony 不引入该压缩通道。
- Rive/ink/glmath → Harmony 的墨迹渲染为自研管线(ADR-0675 等)。

## 结论

原生库版本差 = 崩溃报告 SDK 引入(+4)+压缩库引入(+1)+
MyScript/PDFTron/Rive/ink 内容升级(12 项 size delta)+其余稳定。
全部差异与此前各阶段在依赖清单/资源/代码面登记的结论一致，
本阶段在 .so 文件层完成闭环钉住。
