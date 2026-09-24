# ADR-0642 — 原版 ruler_units 设置行（x22 case 4 + n94 + o59.n/oof）

日期：2026-09-24
状态：已实施（2 项文档化适配；尺具本体按原版 s01.a0 同样隐藏）

## 决策

补齐原版 note_editor 设置区缺失的 ruler_units 行：原版
`x22` case 4 在 straight_lines/shapes_detection/palm_detection/
auto_deselect_eraser 与 language 之间渲染该行；点击打开 `n94`
单位选择器（`oof.N` = Imperial→Metric 两项），点选经 `wb5`→`fr2`
→`ss8` 写 `o59.n`（`rulerUnits` = `oof.I` 序列化字符串），默认
`ub5()` = `oof.IMPERIAL`。

Harmony 落地：

- `EditorSettingsStore`：`RULER_UNITS_KEY='rulerUnits'` +
  `RULER_UNITS_IMPERIAL/METRIC`（与 `oof.I` 同字面值）+
  `DEFAULT_RULER_UNITS=Imperial`；`getRulerUnits()` 对非法值回退
  默认；新增通用 `getStringPref`/`saveStringPref`（互斥锁 + flush
  失败回滚，与既有 boolean 路径同构）。
- `SettingsPage`：`@State rulerUnits` + 加载 + `setRulerUnits()`
  （saveBusy/lifecycleGeneration/回滚/失败 toast 守护）；行置于
  auto_deselect_eraser 与 language 之间（x22 case 3→4→5），尾部
  显示当前单位名；`RulerUnitsDialog` @CustomDialog 复刻
  HandwritingLanguageDialog 形态，oof.N 顺序两项 + 当前项 ✓ +
  点选关闭并写入。

## 适配与差异

1. **尺具本体不移植（与原版一致）**：`s01.a0()` 在全部工具箱列表
   来源中过滤 `a6f.T(RULER)` —— 1.0.3 原版尺具无条件隐藏，属未
   启用功能；Harmony 同样不暴露尺具。`rulerUnits` 偏好当前无
   消费者，与原版 1.0.3 状态完全对齐。若后续版本解封尺具，此
   偏好已按原版键名/序列化落地，可直接消费。
2. **选择器形态**：原版 `n94` 用 Compose `apb.e` 列表项（弹出
   列表）；Harmony 用 `CustomDialogController` + `@CustomDialog`
   复用语言选择器形态，两项顺序、选中标记、点选即写语义等价。
3. **行尾显示**：与 language 行同一惯例显示当前值
   （`vnh.c` 显示名 Imperial/Metric 的本地化对应）。

## 验证

- `d02-original-settings-ruler-units.mjs` 39/39；全量 560/560。
- `note@ohosTest` clean + `note@default` HAP 构建成功。
