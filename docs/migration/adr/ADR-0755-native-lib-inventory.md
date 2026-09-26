# ADR-0755 — 原生 .so 库清单版本差登记

- 状态：Accepted
- 日期：2026-09-21
- 关联：ADR-0745(meta-data/Crashlytics 注册器)、ADR-0747/0750
  (依赖清单/版本 bump)、ADR-0752(Rive 运行时)、Phase 785
  (AppSearch/icing)、Phase 802(OCR 旗标)

## 背景

此前各阶段分别登记了 META-INF 依赖清单、Crashlytics NDK 注册器、
zstd 依赖、Rive 运行时文件数增长。`config.arm64_v8a.apk` 内
`lib/arm64-v8a/*.so` 的文件级清单是同一差异的原生落地层，尚未钉住。

## 决策

1. **登记 +5 新增 .so**:Crashlytics NDK 四件套
   (`libcrashlytics{,-common,-handler,-trampoline}`)与
   `libzstd-jni-1.5.7-4`。与 meta-data 注册器(801)、zstd .version
   条目(798)互证，不构成新面。
2. **登记 12 项 size delta**:MyScript 家族模块、libiink、
   libPDFNetC、librive-android、libink、libglmath 内容升级;
   与 808(Rive 文件数)、798(ink-storage)、794(MyScript res)
   结论一致。
3. **fail-closed 项**:Crashlytics NDK 的原生崩溃报告通道在
   Harmony 无对应设施，不移植；zstd 压缩通道不引入。
4. **语义稳定的原生引擎**(`libicing` AppSearch、
   `libmlkit_google_ocr_pipeline`、libsqliteJni、libtiff*、
   libc++_shared)登记为移植边界:Harmony 侧以 ArkTS/自研管线
   实现等价能力或不实现(后端/厂商依赖部分)。

## 后果

- 原生库层版本差完成登记：+5 新库、0 移除、12 项内容升级，
  全部与既有证据链互证。
- Replay `d02-native-lib-inventory.mjs` 13/13 钉住 xapk 嵌套
  apk 的 .so 清单与大小。
