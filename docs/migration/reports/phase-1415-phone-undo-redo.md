# Phase 1415：窄屏撤销/重做引导气泡 `PHONE_UNDO_REDO` 移植报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 13 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1415-phone-undo-redo.md`
- 决策：`docs/migration/adr/ADR-1351-phone-undo-redo-onboarding.md`
- Replay：`docs/migration/replays/d02-original-phone-undo-redo-tip.mjs`

## 目标

补齐 onboarding 引导链最后一枚可移植条目：原版 `dhb` default
分支在 undo 可用站点（`x90` gl8Var5）按 `jh2.d`（窗口宽 <600dp）
分流——窄屏出 `t0c.M(PHONE_UNDO_REDO)`（槽位 2=锚点下方），宽屏
出 `t0c.L(FIRST_UNDO_REDO)`（槽位 3=锚点左侧）。Harmony 此前仅有
宽屏那一枚。

## 原版证据链

| 层 | 原版类 | 语义 |
|----|--------|------|
| 枚举 | `t0c` | `"PHONE_UNDO_REDO", 9` / `"FIRST_UNDO_REDO", 8` 并存 |
| 分流 | `dhb` default | `zD=jh2.d(…)`；`wv9.b(zD?M:L, zD?2:3, …)` |
| 断点 | `jh2.d` | `z4kVar.a(600)` 宽<600dp → true（窄屏/手机） |
| 槽位 | `tyi` | 3=`b(j2…)` 锚点左侧；2=锚点下方居中（越界上翻） |
| 文案 | `ad` case9/8 | `phone_undo_redo`（Press to undo, long press to redo）/ `first_undo_redo`（双指/三指手势） |
| 持久化 | `hq9` | `onboardingTooltipSeen` Set\<String\>，`pq9.valueOf` 容错 |

## Harmony 实现

1. `OnboardingTooltipStore.ets`：枚举 + 容错表新增
   `PHONE_UNDO_REDO`；其余 5 种缺失条目保持 fail-closed（Learn
   转写 / Google Ink rainbow / 直尺×2 / save-as-template 均无宿主
   或原版自身隐藏）。
2. `EditorToolbar.ets`：
   - `undoTipKind = compact ? PHONE_UNDO_REDO : FIRST_UNDO_REDO`，
     `canUndo` 且该 kind 未见时弹出并锁入
     `@State undoRedoTipKind`；
   - `bindPopup` 位置 `undoRedoTipKind===PHONE_UNDO_REDO ?
     Placement.Bottom : Placement.Left`（= `tyi` 槽位 2/3）；
   - `OnboardingUndoTip` 文案按 kind 分流
     `phone_undo_redo_tooltip_text`（"Press to undo, long press
     to redo" / 点按撤销，长按重做）；
   - `dismissOnboardingTip` 隐藏分支覆盖两枚 kind；seen 集分别
     持久化，互不抑制；
   - `mask:false`/`autoCancel:false` 维持原版非模态语义。
3. 双语字符串 `data_onboarding__phone_undo_redo_tooltip_text`
   （en 逐字对齐 strings.xml；zh 按既有词条风格）。

## 校验

- 本 Phase Replay：13/13 全绿。
- 全量 Desktop Replay：1266/1266 全绿（新增）。
- `note@default` HAP 构建通过；clean `note@ohosTest` 构建通过。

## 遗留

- `SAVE_AS_TEMPLATE` 与其余 4 种 onboarding 条目维持 fail-closed，
  已在 ADR-1351 与 `OnboardingTooltipStore.ets` 注释中备案。
