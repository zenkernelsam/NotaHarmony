# ADR-1141：手写笔触觉偏好（启动初始化器）

## 状态

已接受（Phase 1197）。

## 决策

`HapticPreferencesInitializer`（`g06` Initializer）→
`xj2.A` 协程读/应用手写笔触觉偏好 → Harmony
`EntryAbility` 启动任务 + `@ohos.vibrator`/`haptics` +
Preferences 存储。

## 理由

`implements g06`、`xj2.A(q65,c60)`、`dependencies()=空`、
`NbApplication` instanceof。

## 后果

启动协程配触觉；Harmony 启动任务 + 振动器 API +
偏好存储。
