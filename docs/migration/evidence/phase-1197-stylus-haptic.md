# Phase 1197 证据 — 手写笔触觉（data/stylus/haptic）

来源：`data/stylus/haptic/HapticPreferencesInitializer.java`。

## `HapticPreferencesInitializer implements g06<mof>`

androidx.startup `Initializer`：

```java
create(Context):
  app = context.getApplicationContext()
  if (app instanceof NbApplication)
    xj2.A(q65.I, null, null,
          new c60((NbApplication)app,null,1), 3)   // 启协程
  return mof.a
dependencies() = hw3.I   // 空
```

启动初始化器 → `xj2.A`（协程 launch，`q65` 作用域）→
`c60` 协程读/应用手写笔触觉偏好。

## 判定

手写笔触觉反馈配置 = 应用启动协程：读 haptic 偏好 →
配置手写笔震动反馈（压感触觉）。

## Harmony 决策

- androidx.startup `Initializer` → Harmony `EntryAbility`
  `onCreate`/`onForeground` 启动任务。
- 触觉偏好 → Harmony `@ohos.vibrator`/`haptics`（手写笔
  振动）+ Preferences 存储。

## 产出

- fixture `d02-stylus-haptic.mjs`（10 断言）。
- ADR-1141；中文报告。
