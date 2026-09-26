# ADR-0763 — 运行时偏好存储映射与身份标签修正

## 状态

已接受（已实现并已登记 fail-closed 边界）。

## 背景

Phase 818 后，原版审计轴推进至代码内嵌的运行时持久化表面。扫描
`getSharedPreferences(...)` 字面量与 androidx.startup `*Initializer` 清单后确认：

- 原版使用 16 个 SharedPreferences 文件（3 应用自有 + 13 厂商框架）与
  4 个 proto-DataStore（`user`/`theme`/`settings`/`haptic`），全部自 1.0.1 起存在，
  1.0.1→1.4.2 零增减。
- `backend_override` 持久化 Phase 805 的调试环境选择器结果。
- `widget_bindings` 由 `NoteThumbnailConfigActivity` 维护卡片→笔记绑定。

## 决定

1. **机制等价映射，非文件级克隆**：原版 proto-DataStore（`*.preferences_pb`）在
   Harmony 端由 `@kit.ArkData` preferences KV store 承载
   （`noteEditorSettings` 对应 `settings.preferences_pb`）；卡片绑定由
   FormExtensionAbility 的 formBinding 系统机制等价承载，不单独复制
   `widget_bindings` 文件语义。
2. **vendor prefs 全部 fail-closed**：Firebase/GMS/MLKit/WorkManager/AppSet/OTel
   的 13 个 SharedPreferences 文件是 SDK 内部状态，无应用语义，不迁移。
3. **`backend_override` fail-closed**：调试环境覆盖是 dev 工具通道（ADR-0742 已
   将环境切换器整体 fail-closed），持久化键随之不迁移。
4. **身份标签修正**：`module_desc`/`NoteAbility_desc`/`NoteAbility_label` 的
   DevEco 脚手架值（"module description"/"description"/"label"）修复为真实值；
   应用品牌保持 "NotaHarmony"（ADR-0758 已登记与原版 "Notability" 的身份分叉）。
5. **zh_CN 占位符零偏差**：651 个共享键格式占位符序列逐一比对无差异；
   3 个缺失键即本次修复的身份键，已补齐 zh 值。

## 后果

- 运行时持久化表面闭合：原版 20 个持久化容器全部完成映射或登记边界。
- zh_CN 达到 654/654 全键覆盖且占位符安全。
- 新增 `d02-runtime-prefs.mjs` 回归：清单规模、脚手架标签、占位符一致性与
  Harmony prefs 层存在性。

## 已验证

- `d02-runtime-prefs.mjs`：11/11。
- 全量 Desktop Replay + clean/default/`ohosTest` HAP 构建（随 Phase 819 提交）。
