# Phase 801 报告：AndroidManifest 属性与 meta-data 面收口

日期：2026-09-23
Phase 类型：证据收口（无代码改动）

## 摘要

对原版 1.0.3 ↔ 1.4.2 两份 `AndroidManifest.xml` 做字段级 diff，收口此前未单独
盘点的 `<application>` 属性、`<meta-data>`、`<uses-feature>`、`<queries>`、
`<property>` 维度。结论：除已登记项外零 delta，无新增迁移语义。

## 发现

### 版本间 delta

唯一新增 meta-data：

```
com.google.firebase.components:...crashlytics.ndk.CrashlyticsNdkRegistrar
```

与 Phase 798 登记的 crashlytics-ndk native 库增量同源。

### 完全一致的面

- `<application>` 属性：`allowBackup=false`、`extractNativeLibs=false`、
  `enableOnBackInvokedCallback=true`
- `uses-feature`/`queries`/`property`：归一化 diff 为空
- 4 个应用自有 initializer（AppStartup/User/EditorSettings/HapticPrefs）
  两版本相同——进程内初始化钩子，Harmony 在 Ability `onCreate` 链等价完成

### 语义确认

`allowBackup=false` 表明原版即本地优先、不用 Android 云备份；Harmony 侧备份
由 `NoteBackupAbility`（文件级导出）承担，姿态一致，非行为缺口。

其余 meta-data（GMS/Firebase/MLKit/Play/Stamp + analytics 采集开关）全部为
供应商声明，属既有 fail-closed 边界。

## 验证

- `d02-manifest-attributes.mjs`：6/6 green
- 全量 Desktop Replay：见本节收尾记录
- HAP 构建：default + note@ohosTest 均成功（既有 deprecation 警告，无新增错误）

## 产物

- 证据：`docs/migration/evidence/phase-801-manifest-attributes.md`
- Replay：`docs/migration/replays/d02-manifest-attributes.mjs`
- ADR：`docs/migration/adr/ADR-0745-manifest-attributes.md`
