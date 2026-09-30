# ADR-1239：设置/偏好层

## 状态

已接受（Phase 1295）。

## 决策

Room → `relationalStore`；DataStore+Initializer →
`preferences`/`dataPreferences`+启动钩子。

## 理由

`SettingsDatabase`/`ToolboxDatabase`(x5c Room)+
`ThemeDataStore`/`NoteEditorSettings`/`HapticPrefs`/
`UserDataStore` Initializer（AndroidX Startup）——
设置持久化+启动初始化。

## 后果

Harmony 设置 = relationalStore+preferences —
— 持久化+初始化语义保真。
