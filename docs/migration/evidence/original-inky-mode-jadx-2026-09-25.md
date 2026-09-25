# 原版 Inky 动画吉祥物模式 — JADX 证据（2026-09-25，Phase 708）

## 旗标与状态链

- `ac4.java`：`new ac4("INKY_MODE", 31, zb4Var2, osbVar, null)` →
  `ac4.p0`（序号 31）。
- `w16.java:20`：`lc4.a(ac4.p0) && !z` → `inkyModeAvailable`。
- `z16.java:12`：`new nu2(lc4.f, …, new w16(3,null), 2)` ——
  评估链接入状态流。
- `t9f.java:42-44`：工具栏状态含 `inkyModeAvailable=` +
  `inkyModeEnabled=` 字段。
- `x16.java:62-64`：消费 `k26.a`（enabled）。

## UI 面

- `feature_note__options_menu_inky` = "Inky"（strings.xml）——
  选项菜单开关项，`z22.java:354` 渲染。
- `l26.java:5`：datastore 键 `inky_mode_enabled`；
  `k26.java`：`Data(inkyModeEnabled=…)`，默认 `false`。

## Rive 呈现层

- `h26.java:818/1034`：`e5c.b(RiveFileSource.RawRes.INSTANCE.from(
  R.raw.feature_note_inky__inky_2026_v32,…))`——Rive 动画文件加载。
- `resources/res/raw/feature_note_inky__inky_2026_v32.riv`——
  304 KB 二进制 Rive 资产存在于 APK。
- `h26.java:294/428`：`mx.b(…, "inkyAlpha", …)`——alpha 渐变过渡。

## Harmony 侧核对

- `grep -rln "inky\|rive" note/src` 仅命中 cpp 许可证文本 —
  无 Inky 实现/入口。
- Harmony 无 Rive 运行时（`.riv` 为第三方动画格式）。

## 结论

INKY_MODE 旗标 + Rive 运行时双依赖；Harmony 呈现旗标关闭态，
按 ADR-0656 登记 fail-closed。
