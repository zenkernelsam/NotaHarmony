# Phase 1295 证据 — settings/preferences 层

来源：`data/{settings,toolbar,theme,stylus,subscription}/*`。

## Room 数据库

```
SettingsDatabase extends x5c    // 应用设置 DB
ToolboxDatabase  extends x5c    // 工具栏配置 DB
```

## Startup `Initializer`（AndroidX Startup 初始化器）

```
ThemeDataStoreInitializer        // 主题 DataStore
NoteEditorSettingsInitializer    // 编辑器设置
stylus/haptic/HapticPreferencesInitializer  // 触控笔触觉
core/user/UserDataStoreInitializer          // 用户
```

→ `Initializer<T>` 模式 —— 启动时初始化各 DataStore
（preferences 键值）并注入 `NbApplication`。

## `subscription/storage/SerializationException`
订阅状态序列化存储。

## 语义

**设置/偏好层** = Room DB（持久设置/工具栏）+
Startup Initializer 驱动的 DataStore（主题/编辑器/
触觉/用户偏好）—— 启动期初始化+持久化。

## Harmony 决策

Room → `relationalStore`；DataStore+Initializer →
`preferences`/`dataPreferences`+应用启动钩子 —
— 设置持久化+启动初始化语义保真。

## 产出

- fixture `d02-settings.mjs`（10 断言）。
- ADR-1239；中文报告。
