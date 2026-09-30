# ADR-1111：app 入口 + widget + native 兜底

## 状态

已接受（Phase 1167）。

## 决策

- `MissingNativeLibraryActivity` = native-lib 缺失降级 —
  **先例：原版 fail-soft**（math 渲染降级而非 crash）。
- `NbApplication`/`MainActivity`/`AppUpgradeReceiver`/
  initializers → Harmony `EntryAbility`/`Application`。
- 8 widget（`do2` AppWidgetProvider）→ Harmony
  `FormExtensionAbility` 卡片。

## 依据

`extends Activity`/`extends do2`/`extends BroadcastReceiver`
命名类。

## 后果

Harmony：math 渲染缺失降级（同原版 fail-soft）；
widget → 卡片能力；入口 → EntryAbility。
