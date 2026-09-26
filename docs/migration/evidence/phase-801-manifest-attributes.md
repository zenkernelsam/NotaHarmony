# Phase 801 证据：AndroidManifest 属性与 meta-data 面收口

日期：2026-09-23
输入：`decompiled_1.0.3/resources/AndroidManifest.xml`、
`decompiled_1.4.2/resources/AndroidManifest.xml`（用户预置，jadx 反编译）

本 Phase 收口 manifest 中尚未盘点过的字段维度：`<application>` 顶层属性、
`<meta-data>`、`<uses-feature>`、`<queries>`、`<property>`。
意图：在 Phase 796（intent-filter/deep-link）与 Phase 800（组件清单映射）
之外，确认 manifest 其余字段在 1.0.3 ↔ 1.4.2 之间零新增迁移语义。

## 1. `<application>` 属性（两版本完全一致）

| 属性 | 值 | 语义 |
|------|----|------|
| `android:allowBackup` | `false` | 原版显式禁用 Android Auto Backup；笔记数据为本地优先，不进入 Google 云备份 |
| `android:extractNativeLibs` | `false` | native 库从 APK 直接 mmap（打包标准姿势，无迁移语义） |
| `android:enableOnBackInvokedCallback` | `true` | 启用预测性返回回调（Android 13+ UX 行为，Harmony 侧返回手势为系统能力） |

未出现：`fullBackupContent`、`dataExtractionRules`、`backupAgent`、
`networkSecurityConfig`、`usesNonSdkApi`、`requestLegacyExternalStorage`、
`localeConfig`（1.4.2 走 locale split APK 而非 per-app locale API）。

### 对 Harmony 侧的映射

- `allowBackup=false` 与 NotaHarmony 的本地优先设计一致：Harmony 侧备份语义由
  `NoteBackupAbility`（文件级导出备份）承担，而非平台云备份——原版本来就不用平台
  备份，语义等价。
- `extractNativeLibs` / `enableOnBackInvokedCallback` 为平台打包/UX 标志，
  Harmony 无对应物且无行为缺口。

## 2. `<meta-data>` 清单（1.4.2 共 44 项，delta = +1）

唯一新增项：

```
com.google.firebase.components:com.google.firebase.crashlytics.ndk.CrashlyticsNdkRegistrar
```

对应 Phase 798 已登记的 `libcrashlytics-*` native 库增量（NDK 崩溃报告
registrar）。无独立迁移语义。

### 应用自身 initializer（4 项，两版本相同）

- `app.initializers.AppStartupInitializer`
- `core.user.UserDataStoreInitializer`
- `data.settings.NoteEditorSettingsInitializer`
- `data.stylus.haptic.HapticPreferencesInitializer`

语义：App Startup 风格的进程初始化钩子（DI/DataStore 预热）。Harmony 侧模块
初始化在 Ability `onCreate` 链中完成，无对应缺口。

### 供应商 meta-data（全部 fail-closed 已登记）

- GMS：`com.google.android.gms.version`、CREDENTIAL_PROVIDER_KEY
- Firebase 全家桶：Analytics/Crashlytics(+NDK)/Perf/RemoteConfig/Sessions/
  Installations/ABT/datatransport + `firebase_*_collection` 开关 +
  `google_analytics_adid_collection_enabled`
- ML Kit：Vision/Text/Common registrar
- Play：billingclient.version、assetpacks.versionCode、vending.splits.*
- Stamp：`com.android.stamp.source/type`（APK 安装来源校验）
- androidx：EmojiCompat/ProcessLifecycle/ProfileInstaller/Apollo/okhttp
  PlatformInitializer、`FILE_PROVIDER_PATHS`（Phase 800 ExportFileProvider 映射）

## 3. uses-feature / queries / property / intent 顶层元素

以属性值归一化后做 sort+diff：**两版本完全一致**（`diff` 无输出）。

- `uses-feature` 仅相机可选特性（camera/any/autofocus/flash）与横竖屏——Harmony
  `module.json5` `requestPermissions`/`deviceTypes` 已覆盖对应能力声明。
- `<queries>`（包可见性）两版本无差异。
- `PROPERTY_SUPPORTS_MULTI_INSTANCE_SYSTEM_UI`（桌面多实例）在两版本相同，
  Harmony 无对应物（单窗口语义内由 UI 层处理）。

## 4. 结论

manifest 字段级收口完成：除已登记的 intent-filter（Phase 796）、组件清单
（Phase 800）、`READ_CALENDAR`（Phase 784）、`IMAGE_CAPTURE_SECURE`
（Phase 760）与本次 `CrashlyticsNdkRegistrar`（关联 Phase 798）之外，
manifest 其余字段在 1.0.3 ↔ 1.4.2 间**零 delta**。`allowBackup=false`
确认原版本地优先数据姿态，与 Harmony 文件级备份映射语义一致。
