# ADR-0745：manifest 属性与 meta-data 面收口

- 状态：accepted
- 日期：2026-09-23
- 证据：`docs/migration/evidence/phase-801-manifest-attributes.md`
- Replay：`docs/migration/replays/d02-manifest-attributes.mjs`

## 决定

AndroidManifest 非组件字段面按"零 delta + fail-closed"收口：不新增 Harmony
实现工作，全部登记为版本/平台差异证据。

## 依据

逐字段 diff（`<application>` 属性、`<meta-data>`、`<uses-feature>`、
`<queries>`、`<property>`）在 1.0.3 ↔ 1.4.2 间仅一处新增：
`CrashlyticsNdkRegistrar` meta-data，与 Phase 798 已登记的 crashlytics-ndk
native 库同源，无独立迁移语义。

## 关键事实

- `allowBackup=false`：原版显式禁用平台云备份；Harmony 侧备份语义由
  `NoteBackupAbility` 文件级导出承担，姿态一致。
- 4 个应用自有 initializer（AppStartup/User/EditorSettings/HapticPrefs）
  为进程内 DI/DataStore 预热钩子，Harmony 在 Ability `onCreate` 链内完成
  等价初始化，无缺口。
- 其余 meta-data 全部为 GMS/Firebase/MLKit/Play/Stamp 供应商声明，
  属既有 fail-closed 边界。

## 影响

manifest 证据面至此完整关闭（组件：Phase 800；intent-filter：Phase 796；
权限 delta：Phase 784；属性/meta-data：本 Phase）。无需修改 Harmony 代码。
