# Phase 678 — 原版选区菜单 `dsc` 全表对账（fail-closed 登记）

- 日期：2026-09-22
- 状态：已完成（登记/注释类，无行为变更）
- ADR：ADR-0645
- 证据：`docs/migration/evidence/phase-678-original-selection-menu-dsc-reconcile.md`
- Fixture：`docs/migration/replays/d02-original-selection-menu-dsc-reconcile.mjs`（43/43）

## 范围

对 `dsc.java` 选区菜单 22 项动作枚举与 Harmony `SelectionMenuAction`
做全表对账，补齐遗留 4 项的定性登记：

| 原版项 | 原版语义 | Harmony 判定 |
| --- | --- | --- |
| CONVERT_TO_MATH (11) | `xsc.p()` 探测 j4e/MyScript 后端 → 跨页校验 → iink 识别替换为数学块 | fail-closed 缺省 |
| CONVERT_TO_TEXT (12) | 同上管线，笔画过滤后替换为文本块 | fail-closed 缺省 |
| FIT_TO_PAGE (15) | `throw new NotImplementedError(0)` | 原版即死桩，缺省正确 |
| MORE (21) | 翻转 `msc.b`（esc 双行 options 显隐） | 单行 `bindMenu` 全量列出（适配） |

其余 18 项已覆盖（含 ADR-0586 的 LOCK/UNLOCK 开关合并）；Harmony
另有 PASTE/DESELECT_CONFIRM/CANCEL 三个已注册适配项。

## 关键证据

- `dhb.java:17696/17811` case11/12 派发：`xsc.p()` 后端探测 +
  `ba6.o` 页面门禁 + `xsc.v` 跨页校验，识别走 `com.myscript.iink`
  （商业闭源 SDK 随 APK 打包）。
- `dhb.java:17985` case15 死桩。
- `dhb.java:18045` case21 仅翻转 `msc.b`。
- Harmony 侧 `OriginalHandwritingConversionCoordinator` 已按
  `dhb` case12 管线搭好（选区笔画快照 → recognizer → planner →
  freshness → persistence），唯 `OriginalHandwritingRecognitionProvider`
  无生产实现 → 与原版「后端不可用则菜单项不渲染」等价。

## Harmony 变更

- `SelectionOverlay.ets` 菜单注释升级为全表口径并引用 ADR-0645。
- 无代码行为变更、无字符串变更。

## 验证

- 专用 fixture：43/43（枚举钉 + 派发钉 + 字符串钉 + Harmony
  覆盖钉 + fail-closed 钉）。
- 全量 Desktop Replay：562/562，FAIL=0。
- `note@ohosTest` clean HAP：BUILD SUCCESSFUL。
- `note@default` HAP：BUILD SUCCESSFUL。
- 构建仅含既有 deprecation/exception 警告，无编译错误。
- 未进行设备/模拟器/Hypium 运行时验证。

## 后续接入点

若未来引入 OCR 提供方，`runOriginalHandwritingConversion` 即是
CONVERT_TO_TEXT 的落点（选区笔画 → `xsc.v` 等价跨页校验 →
识别 → 文本块替换）；CONVERT_TO_MATH 需另建数学识别器后再评估。
