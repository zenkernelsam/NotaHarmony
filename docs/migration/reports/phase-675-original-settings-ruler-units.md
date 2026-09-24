# Phase 675 报告：原版 ruler_units 设置行

## 摘要

补齐 note_editor 设置区最后一块非服务端缺口：原版 `x22` case 4
的 `feature_settings__ruler_units` 行 + `n94` 单位选择器 +
`o59.n`/`oof` 持久化。Harmony 现按原版行序（x22 0→5）完整覆盖
全部六项编辑器偏好。

同时完成原版尺具（a6f.T RULER）审计：确认其在 1.0.3 被 `s01.a0`
从所有工具箱列表无条件过滤——原版即未启用；Harmony 同样不暴露，
对齐而非缺失（详见 ADR-0642）。

## 原版证据

- `x22.java` case 4：渲染 `feature_settings__ruler_units`（"Ruler units"）。
- `n94.java` case 1：遍历 `oof.N=[IMPERIAL,METRIC]` 构造选择项，
  `vc` 回调 → `wb5` → `fr2` → `ss8` case 8 写 `o59.n`。
- `o59.java`：`n = eua("rulerUnits")`；`oof.I` = "Imperial"/"Metric"。
- `ub5.java`：默认 `rulerUnits=IMPERIAL`。
- `s01.java` `a0()`：`!= a6f.T` 过滤尺具（tl7/cq/b7f/ys2 全部列表源）。

## 实现

| 文件 | 改动 |
|------|------|
| `note/src/main/ets/data/EditorSettingsStore.ets` | `rulerUnits` 键 + Imperial/Metric 常量 + 默认 IMPERIAL + `getStringPref`/`saveStringPref` 通用助手 + `getRulerUnits`/`saveRulerUnits`（非法值回退默认） |
| `note/src/main/ets/ui/settings/SettingsPage.ets` | `@State rulerUnits` + 加载 + `setRulerUnits` 守护写入 + 行（x22 case 4 位置，尾部当前值）+ `RulerUnitsDialog` 选择器 |
| `note/src/main/resources/base/element/string.json` | `ruler_units`/`imperial`/`metric` |
| `note/src/main/resources/zh_CN/element/string.json` | 标尺单位/英制/公制 |
| `note/src/test/EditorViewModel.test.ets` | fake 仓库补 `getRulerUnits`/`saveRulerUnits` |
| `docs/migration/replays/d02-original-settings-ruler-units.mjs` | 新增 39 断言 |

## 验证

- 新增 fixture：39/39。
- 全量 Desktop Replay：560/560，FAIL=0。
- `note@ohosTest` clean HAP 构建成功。
- `note@default` HAP 构建成功。
- 无模拟器/真机/Hypium 验证。

## 后续

- 尺具本体（a6f.T + ho5.t 图标 + rulerUnits 消费端）：原版 1.0.3
  门控隐藏；若 1.4.2 解封，待 T-042 版本分析时复核。
