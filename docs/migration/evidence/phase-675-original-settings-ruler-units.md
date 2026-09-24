# Phase 675 证据：原版 ruler_units 设置行（x22 case 4 + n94 + o59.n/oof）

## 原版证据（decompiled_1.0.3）

### 设置行位置与标签

`sources/defpackage/x22.java` case 4：

```java
tpe.b(tl7.U(uz4Var5, R.string.feature_settings__ruler_units), ...);
```

`x22` 的设置区行序为 straight_lines(0) → shapes_detection(1) →
palm_detection(2) → auto_deselect_eraser(3) → **ruler_units(4)** →
language(5)。`feature_settings__ruler_units` 原文 `"Ruler units"`。

### 单位选择器

`sources/defpackage/n94.java` case 1：遍历 `oof.N`（nz3 列表，顺序
`[IMPERIAL, METRIC]`），每个单位构造一个 `apb.e` 列表项
（`o22` 组合内容 + `vc` 点击回调），点选进入
`wb5.h()` → `fr2` → `ss8` case 8：

```java
tk8Var2.g(o59.n, oofVar.I);   // 写 "rulerUnits" = "Imperial"/"Metric"
```

`vnh.c(oof)` 把枚举映射为显示名
`feature_settings__imperial` / `feature_settings__metric`
（"Imperial" / "Metric"）。

### 持久化键与默认值

- `o59.java`：`public static final eua n = new eua("rulerUnits")` ——
  DataStore 键名与序列化值 `oof.I`。
- `oof.java`：`IMPERIAL("Imperial")`、`METRIC("Metric")`，
  `N = [IMPERIAL, METRIC]`。
- `ub5.java`：`ub5()` 默认 `rulerUnits = oof.IMPERIAL`
  （同对象内 straightLinesEnabled/shapesDetectionEnabled/
  palmDetectionEnabled/autoDeselectEraser 全部已有对应移植）。

### 尺具本身的门控（背景）

`a6f.T` = RULER 工具（`xb4` 序列化、`ho5.t` 图标、`x82` case 11 标签
`ui_tools__ruler`、`i5f` 工具配置、`w4g.a` 无笔宽档）。
但 `s01.a0()` 在**所有**工具箱列表来源（`tl7`/`cq`/`b7f` 工具栏三行、
`ys2` 收藏工具行）中执行 `r5fVar.g() != a6f.T` 过滤——1.0.3 中尺具
被无条件隐藏，属未启用功能。原版的 `ruler_units` 设置行仍然渲染，
本 Phase 按原版可见表面移植该行；尺具本体的缺失另在 ADR 登记。

## Harmony 实现映射

| 原版 | Harmony |
|------|---------|
| `o59.n` eua("rulerUnits") | `EditorSettingsStore.RULER_UNITS_KEY = 'rulerUnits'` |
| `oof.I` 序列化 | `RULER_UNITS_IMPERIAL='Imperial'` / `RULER_UNITS_METRIC='Metric'` |
| `ub5()` 默认 IMPERIAL | `DEFAULT_RULER_UNITS = RULER_UNITS_IMPERIAL` |
| `n94` apb.e 列表项 ×2 | `RulerUnitsDialog` ForEach 两项 + 当前项 ✓ |
| `vc`→`wb5`→`ss8` 写入 | `setRulerUnits()` → `saveRulerUnits()`（互斥锁+回滚） |
| x22 case 4 行位置 | `SettingsPage` auto_deselect_eraser 与 language 之间 |
| `vnh.c` 显示名 | 行尾 `imperial`/`metric` 字符串 |

## 差异声明

- 原版尺具（a6f.T）被 `s01.a0` 无条件隐藏；Harmony 同样不暴露尺具，
  属对齐而非缺失。`rulerUnits` 值当前无尺具消费者，与原版 1.0.3
  状态一致（该行在原版中同样只是可见偏好）。
- 选择器交互：原版 `n94` 用 `apb.e` 列表项；Harmony 用
  `CustomDialogController` + `@CustomDialog`（与既有
  HandwritingLanguageDialog 同一形态），勾选标记与点选即写语义一致。

## 验证

- `d02-original-settings-ruler-units.mjs`：39/39。
- 全量 Replay：559→560 全绿（本 Phase 新增 1 fixture）。
- `note@ohosTest` clean HAP、`note@default` HAP 均构建成功。
- 未做模拟器/真机/Hypium 验证。
