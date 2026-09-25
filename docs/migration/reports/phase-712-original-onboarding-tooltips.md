# Phase 712：原版引导气泡链（pq9 onboardingTooltipSeen）移植

字符串族审计续：`data_onboarding__*`（13 条）为本地 UI 引导
气泡系统——非私有后端功能，判定可移植并完整实现。

## 原版证据链

- `pq9.java`：12 种气泡枚举（NEW_NOTE…COMPACT_ORGANIZE）。
- `hq9.java`：datastore 键 `onboardingTooltipSeen` 持久化
  `Set<String>` 枚举名，`pq9.valueOf` 容错读回。
- `fsi.h/g`：站点条件 `!seen && 上下文`；`zy7` 气泡 +
  `k9f` 方位回退（1上/2下/3左/4右/RTL）；`js7` "Got it" 写回。
- 站点逐位：x90:10523 `fsi.h(pq9.N,3,z7)`（页管理器·有内容）、
  x90:10528 `fsi.h(pq9.O,3,undo可用)`、ajh:406 `pq9.P`（库侧·右）、
  enh:28 `fsi.h(pq9.Q,2)`（Folders·下）、ipi `pq9.J`、gaj `pq9.L`、
  rh8 e5f→`pq9.I`/k5f→`pq9.K`（笔记态机）+ `seen(I)` 前置
  （L/J 均以此为前置）。
- `FIRST_TRANSCRIPT`（`pq9.M`）走 `cqi` → feature_learn 转写面，
  已在 ADR-0652 fail-closed，不带入本链。

## 决定

- 移植 11 条气泡 + "Got it"：`OnboardingTooltipStore`（prefs
  逗号串等价 Set<String>，键名逐位）+ `OnboardingTipBubble`
  （深色气泡 + Got it）。
- 工具栏锚点走 `bindPopup`：`mask:false` 保持原版非模态、
  `autoCancel:false` 保持仅 Got it 关闭；pos3→Left、pos4→Right、
  pos2→Bottom。
- 元素锚点（INK_INSERT/IMAGE）走画布浮层 + `tipOverlayPosition`
  复现 k9f 越界回退。
- 前置序逐位：TRAY/RECORDING 均要求 `seen(NEW_NOTE)`。
- 12 条 `data_onboarding__*` 键名/英文与原版逐位一致，中文
  等义直译。

## 差异记录（ADR-0660）

- NEW_NOTE/INK_INSERT/IMAGE/TEXT/HIGHLIGHTER 原版锚点为通用
  宿主 `i01` 自适应方位，静态证据不足；按文案语义锚定所述
  控件或元素包围盒，方位取 k9f 默认回退——证据表逐条标注。

## 验证

- `d02-original-onboarding-tooltips.mjs`（95 断言：原版枚举/
  站点/方位/文案 + Harmony store/气泡/六锚点/双 locale/文档）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
