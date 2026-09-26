# Phase 819 — 运行时偏好存储清单闭合 + 身份标签缺陷修复

## 范围

原版代码内嵌持久化表面审计：SharedPreferences 文件清单、proto-DataStore 清单、
版本差分、Harmony 持久层映射；顺带完成 zh_CN 占位符一致性审计并修复发现的
脚手架标签缺陷。

## 原版证据

### SharedPreferences（16 个文件，1.0.3/1.4.2 同名集合）

**应用自有（3 个）**：`backend_override`（调试环境覆盖持久化，佐证 Phase 805）、
`search_engine`（搜索引擎状态）、`widget_bindings`（`NoteThumbnailConfigActivity`
的卡片→笔记绑定）。三者均自 1.0.3 起存在。

**厂商/框架（13 个）**：Firebase Perf/Crashlytics/Common/RemoteConfig(`frc_`)、
GMS measurement/signin、MLKit internal、WorkManager×2、AppSet、app_update、
Analytics deferred deeplink、OpenTelemetry——全部为 SDK 内部状态，fail-closed。

### Proto-DataStore（4 个 store，自 1.0.1 起存在）

`rm7`（androidx.startup.Initializer）实现 + `@Metadata` 文件名后缀确认：
`user.preferences_pb`、`theme.preferences_pb`、`settings.preferences_pb`、
`haptic.preferences_pb`——用户/主题/编辑器设置/触控笔触感四路 proto store，
共用 `egj` 序列化器。1.0.1→1.4.2 **零增减**。

## 发现的缺陷与修复

**脚手架标签残留**：`module.json5` 实际引用的三个键仍为 DevEco 占位值——
`module_desc`="module description"、`NoteAbility_desc`="description"、
`NoteAbility_label`="label"。已修复为真实值（"NotaHarmony notes module"/
"Create and edit notes"/"NotaHarmony"），并补齐 zh_CN 对应键
（"NotaHarmony 笔记模块"/"创建和编辑笔记"/"NotaHarmony"）。

应用品牌保持 "NotaHarmony"（与 `AppScope.app_name` 一致；与原版 "Notability"
的分叉已在 Phase 794 登记）。

## zh_CN 审计结果

- 651 个共享键 `%d`/`%s`/`%N$s` 占位符序列逐一比对：**0 不匹配**。
- 缺失键恰好为本次修复的 3 个身份键，已补齐 → zh_CN 达到 654/654 全键覆盖。
- 多余键 0：zh_CN 为 base 纯净子集。

## 交付物

- 证据：`docs/migration/evidence/phase-819-runtime-prefs-identity.md`
- ADR：`docs/migration/adr/ADR-0763-runtime-prefs-identity.md`
- Replay：`docs/migration/replays/d02-runtime-prefs.mjs`（11 项断言）
- 代码：`note/src/main/resources/base/element/string.json`、
  `zh_CN/element/string.json`

## 验证

- 新增 Replay：11/11 通过。
- 全量 Desktop Replay、clean/default 与 `note@ohosTest` HAP 构建随本 Phase 完成。

## 下一步

持久化表面闭合。后续轴：原版 APK 内 `assets/` 之外的二进制载荷、
混淆字符串表（jadx 内联常量池）或元数据级残留审计。
