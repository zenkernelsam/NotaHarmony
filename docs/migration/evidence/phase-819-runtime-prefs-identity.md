# Phase 819 — 运行时偏好存储清单 + 应用身份标签审计

证据来源：`decompiled_1.0.1/1.0.3/1.4.2`（`getSharedPreferences` 全量扫描、`*Initializer` 类、Kotlin `@Metadata`）；Harmony `note/src/main/ets/data/`、`resources/*/element/string.json`、`module.json5`、`AppScope/`。

## 一、原版 SharedPreferences 文件清单（16 个）

`getSharedPreferences("...")` 字面量全量扫描（1.0.3 vs 1.4.2 同名集合）：

### 应用自有（3 个，全部自 1.0.3 起存在）

| 文件名 | 消费者 | 语义 |
|---|---|---|
| `backend_override` | `LoggingInitializer` + 混淆类 | 环境覆盖——Phase 805 调试环境选择器的持久化（42 环境枚举） |
| `search_engine` | 混淆类 | 搜索引擎运行状态 |
| `widget_bindings` | `NoteThumbnailConfigActivity` | 桌面 widget → 笔记绑定（缩略图 widget 记住目标笔记） |

### 厂商/框架（13 个，全部随 SDK 携带）

| 文件名 | 归属 |
|---|---|
| `FirebasePerfSharedPrefs` | Firebase Performance |
| `androidx.work.util.id` / `androidx.work.util.preferences` | WorkManager |
| `app_set_id_storage` | Play AppSet（817 已登记） |
| `app_update` | Play 应用内更新 |
| `com.google.android.gms.measurement.prefs` | Google Analytics |
| `com.google.android.gms.signin` | GMS 登录 |
| `com.google.firebase.common.prefs:` | Firebase Common |
| `com.google.firebase.crashlytics` | Crashlytics |
| `com.google.mlkit.internal` | MLKit |
| `frc_` | Firebase RemoteConfig（802 已登记） |
| `google.analytics.deferred.deeplink.prefs` | Analytics 延迟深链 |
| `opentelemetry-android` | OpenTelemetry |

厂商键一律 fail-closed——Harmony 无对应 SDK，且无应用语义。

## 二、原版 Proto-DataStore 清单（4 个，自 1.0.1 起存在）

`rm7`（androidx.startup.Initializer）实现类 + `@Metadata` d2 文件名后缀：

| DataStore 文件 | 初始化器 | 语义 | Harmony 对应 |
|---|---|---|---|
| `user.preferences_pb` | `core/user/UserDataStoreInitializer` | 用户偏好 proto | 本地优先无账号层——见 §四 |
| `theme.preferences_pb` | `data/theme/ThemeDataStoreInitializer` | 主题偏好 | `ThemeStore`/主题设置 |
| `settings.preferences_pb` | `data/settings/NoteEditorSettingsInitializer` | 编辑器设置 | `noteEditorSettings`（`EditorSettingsStore`） |
| `haptic.preferences_pb` | `data/stylus/haptic/HapticPreferencesInitializer` | 触控笔触感反馈 | SPen 触感——Harmony 触感 API 差异域 |

四个 store 共用同一 `egj` 序列化器（proto-javalite）。全部三版本均存在——
**1.0.1→1.4.2 零 store 增减**，与 812/815/818 的版本增量画像一致。

`user.preferences_pb.bin` 残留物已在参考根目录发现（19 字节样本），佐证该 store
为二进制 proto 而非 XML。

## 三、Harmony 持久层映射结论

| 原版 | Harmony | 状态 |
|---|---|---|
| `settings.preferences_pb` | `data/EditorSettingsStore`（`preferences.getPreferences`，store 名 `noteEditorSettings`） | 已覆盖 |
| `onboardingTooltipPreferences` / `OriginalHandwritingLanguagePreferenceStore` / `WebDAVConfigStore` | Harmony 自有持久化 | Harmony 新增（无原版对应项） |
| `widget_bindings` | Harmony FormExtensionAbility 的 formBinding（系统托管卡片↔数据绑定） | 平台等价机制 |
| `backend_override` | 无（调试环境选择器为 fail-closed dev 工具，805 已登记） | fail-closed |
| `user`/`theme`/`haptic` proto | 主题在用户设置层；user/haptic 为 Android proto 形态——Harmony 用 preferences KV 等价承载 | 机制等价 |

## 四、应用身份标签审计（本次发现的缺陷）

| 项 | 原版 | Harmony（修复前） | 处置 |
|---|---|---|---|
| 应用 label | `app_name`="Notability" | `app_name`="NotaHarmony" | 保留 NotaHarmony 品牌（794 已登记身份分叉） |
| Ability label | `android:label="@string/app_name"` | `NoteAbility_label`="label"（脚手架残留） | **修复→"NotaHarmony"** |
| module_desc | — | `"module description"`（脚手架） | **修复→"NotaHarmony notes module"** |
| NoteAbility_desc | — | `"description"`（脚手架） | **修复→"Create and edit notes"** |

DevEco 脚手架占位值残留在三个被 `module.json5` 实际引用的键中，此前未被发现。

## 五、zh_CN 占位符一致性审计

对 base/zh_CN 共享 651 个键逐一比对 `%d`/`%s`/`%1$s` 等格式占位符序列：

- **占位符不匹配：0**——zh_CN 翻译完整保留全部格式说明符，无运行时格式化崩溃风险。
- zh 缺失键：恰好是上述 3 个脚手架键 → 本 Phase 补齐（`module_desc`/`NoteAbility_desc`/`NoteAbility_label` 的 zh 值）。
- zh 多余键：0——zh_CN 是 base 的纯净子集。

## 六、结论

运行时偏好表面闭合并双端对齐：原版 4 proto-DataStore + 3 app SharedPrefs + 13 vendor
prefs 全部登记；`backend_override` 佐证 805 环境切换器；其余 vendor 键 fail-closed。
同时修复一个真实缺陷（Ability/模块标签脚手架残留）并证明 zh_CN 占位符零偏差。
