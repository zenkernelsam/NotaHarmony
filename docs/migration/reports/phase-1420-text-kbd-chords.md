# Phase 1420：文本编辑键盘和弦补齐与 DESELECT 更正报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 15 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1420-text-kbd-chords.md`
- 决策：`docs/migration/adr/ADR-1356-text-kbd-chords.md`
- Replay：`docs/migration/replays/d02-original-text-kbd-chords.mjs`

## 目标

补齐原版文本编辑器和弦缺口并更正一处误植：原版 `syh`（帮助表，
`ra8→qa8`）+ `e0b`（`h3a`/`ya8` 真实 KeyEvent 分发器）显示，
Harmony 的 `onEditorKeyEvent` 缺少列表装饰切换（Ctrl+Shift+B/L/C）、
字号步进（Alt±Ctrl+Up/Down）两组和弦，且 DESELECT 误绑 Ctrl+D
（原版实为 Ctrl+\\，`zs9.l=ofk.e(73)=KEYCODE_BACKSLASH`）。

## 原版证据链

| 项 | 原版锚点 | 解码 |
|----|----------|------|
| 掩码语义 | `qa8` 三参构造 | `(i2&2)==0,(i2&4)==0,(i2&8)==0` — bit 置位=修饰缺席 |
| 列表切换 | `syh` qa8(30/40/31,4) | Ctrl+Shift+B/L/C → TOGGLE_BULLET/NUMBERED/CHECKLIST_LIST |
| 字号步进 | `e0b` else 支 + `syh` qa8(19/20,8) | 运行时 Alt+Up/Down；帮助表 Ctrl+Alt+Up/Down |
| DESELECT | `e0b` `pa8.a(jE2,zs9.l)`、`syh` qa8(73,12) | Ctrl+\\（Android 73=BACKSLASH） |

## Harmony 实现（`TextBlockOverlay.ets`）

`onEditorKeyEvent` 增读 `alt`/`shift` 修饰位，按特异性降序排列四个
分发支：`ctrl&&alt&&!shift` → `stepFontSize(±1)`；
`ctrl&&shift&&!alt` → `toggleDecoratorStyle(1/2/3)`（键码
2018/2028/2019）；`alt&&!shift` → `stepFontSize(±1)`（e0b 运行时，
键码 2012/2013）；`ctrl&&!alt&&!shift` → 既有 B/I/U/A/Home/End +
DESELECT 改绑 2061（2020 已移除）。守卫沿用 `KeyType.Down` +
`photoImportLeaseActive`；未消费组合返回 false。

## 差异登记（维持/新增）

- `syh` Alt+Up/Down→HOME/END 与 `e0b` 字号分发同键：以运行时为准，
  文首/文末经既有 Ctrl+Home/End(2081/2082) 覆盖。
- `e0b` 另有 `!ctrl&&shift`+B/L/C 支疑脱字（与 Shift 大写冲突），
  以 `syh` Ctrl+Shift 契约为准，见 ADR-1356。
- Ctrl+Z/Y、Ctrl+X/C/V 缺口登记不变。

## 验证

- `d02-original-text-kbd-chords.mjs`：15/15 绿。
- `d02-original-text-keymap.mjs` Ctrl+D 钉重锚 2061 后绿；
  `d02-input-surfaces` / `d02-original-keyboard-shortcuts` 等邻域绿。
- `REPLAY_BASELINE PASS=1272 FAIL=0`。
- `hvigorw assembleHap -p module=note@default`：BUILD SUCCESSFUL。
- clean + `assembleHap -p module=note@ohosTest`：BUILD SUCCESSFUL
  （`OhosTestCompileArkTS` 实际执行）。

## 提交内容

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `docs/migration/replays/d02-original-text-kbd-chords.mjs`（新）
- `docs/migration/replays/d02-original-text-keymap.mjs`（重锚）
- 证据/ADR/报告 + 三份追踪文档
