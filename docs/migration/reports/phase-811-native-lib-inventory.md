# Phase 811 — 原生 .so 库清单版本差(中文报告)

## 本阶段结论

`config.arm64_v8a.apk` 内原生库清单完成文件级版本对比:
**26 → 31,零移除,+5 新增,12 项大小升级**。

## 新增 5 项

- `libcrashlytics{,-common,-handler,-trampoline}.so` —— Firebase
  Crashlytics NDK,与 Phase 801 登记的 meta-data
  `CrashlyticsNdkRegistrar` 为同一依赖的注册层/打包层双重证据;
  Harmony 无原生崩溃报告通道,fail-closed。
- `libzstd-jni-1.5.7-4.so` —— zstd 压缩 JNI,与 Phase 798 的
  `zstd-jni` .version 条目互证。

## 12 项大小升级(内容 delta)

| .so | Δ | 互证 |
|---|---|---|
| librive-android | +14.1% | Phase 808 Rive 256→485 文件升级 |
| libink | +7.5% | Phase 798 ink-storage / 778 nib 模型 |
| libiink / libMyScript* | +0.1~5.5% | MyScript SDK 整体升级(794 res delta) |
| libPDFNetC | +1.7% | PDFTron 引擎升级 |
| libglmath | +2.3% | 数学渲染辅助 |

## 稳定核心(大小不变)

`libicing`(AppSearch)、`libmlkit_google_ocr_pipeline`(MLKit OCR)、
`libsqliteJni`、`libtiff*`、`libc++_shared`、`libdatastore_shared_counter`
等 14 项两版大小一致 —— 基础设施与厂商引擎层稳定。

## 验证

- Replay:`d02-native-lib-inventory.mjs` 13/13(xapk 嵌套 zip
  解析钉住 .so 名与未压缩大小);全量 684/684 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `docs/migration/evidence/phase-811-native-lib-inventory.md`
- `docs/migration/replays/d02-native-lib-inventory.mjs`
- `docs/migration/adr/ADR-0755-native-lib-inventory.md`
- 本报告
