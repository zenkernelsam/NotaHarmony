# ADR-1356 文本编辑键盘和弦补齐与 DESELECT 更正

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1420
- 接续：ADR-1135（文本编辑）；证据：`docs/migration/evidence/phase-1420-text-kbd-chords.md`

## 背景

原版文本域 KeyEvent 分发器 `e0b`（`h3a`/`ya8` 拦截链）+ 帮助表
`syh`（`txm` 分组注册的 `ra8→qa8` 映射）构成完整和弦契约。
Harmony 的 `onEditorKeyEvent`（Phase 695 起）已覆盖
B/I/U/A/Home/End/Esc/Tab，但缺三组和弦且一处误植：

1. **缺**列表装饰切换：Ctrl+Shift+B/L/C → bullet/numbered/checklist
   （`syh qa8(30/40/31,4)`，mask 反码 4=alt 缺席→ctrl+shift）。
2. **缺**字号步进：`e0b` 运行时为 Alt+Up/Down；`syh` 帮助表列
   Ctrl+Alt+Up/Down（qa8(19/20,8)）。
3. **误植**：DESELECT 被绑到 Ctrl+D(2020)。原版两处证据一致指向
   键码 73=`KEYCODE_BACKSLASH`：`zs9.l=ofk.e(73)`（e0b 的
   `pa8.a(jE2, zs9.l)` → DESELECT）与 `syh qa8(73,12)`。Harmony 键码
   2061（Android 73+1988，与既有标点区偏移一致）。

## 决策

1. `onEditorKeyEvent` 增读 alt/shift 修饰，按特异性降序分发：
   `ctrl&&alt&&!shift`（syh 字号）→ `ctrl&&shift&&!alt`（列表切换）→
   `alt&&!shift`（e0b 运行时字号）→ `ctrl&&!alt&&!shift`（既有
   B/I/U/A/Home/End/Backslash）。特异性排序保证 Ctrl+Shift+B 不落入
   加粗分支。
2. 字号步进双绑定（Alt 与 Ctrl+Alt 变体皆 → `stepFontSize(±1)`）：
   `e0b` 运行时门与 `syh` 帮助表对同一 `ra8` 给出不同和弦，取超集
   覆盖——两者互不冲突且均为原版证据所支持。
3. DESELECT 改绑 2061；2020(D) 不再消费（原版 Ctrl+D 未分配）。
4. 列表切换采用 `syh` 契约 Ctrl+Shift+×：`e0b` 中另有
   `!ctrl&&shift`+B/L/C 支，若字面执行会与 Shift 大写输入冲突，
   判定为脱字/门上下文差异，以用户可见帮助表为准并在此登记。
5. `syh` 的 Alt+Up/Down→HOME/END 与 `e0b` 字号分发同键冲突，
   以运行时为准；文首/文末经既有 Ctrl+Home/End 覆盖。

## 备选与拒绝

- **Shift-only B/L/C**（e0b 字面）：拒绝——与大写输入冲突，疑脱字。
- **仅 Ctrl+Alt 字号**（仅 syh）：拒绝——遗漏 e0b 运行时的
  Alt+Up/Down 真实分发。
- **新增文本模型方法**：拒绝——`toggleDecoratorStyle(1/2/3)` 与
  `stepFontSize(±1)` 已是原版 `cve` 步进钮同路径操作，直接复用。

## 后果

- 新增和弦全部走既有操作，零模型改动；纯 Ctrl 分支加 `!shift&&!alt`
  守卫消歧。
- fail-closed 维持：Ctrl+Z/Y（无草稿级 undo 基建）；Ctrl+X/C/V 走
  TextArea 原生剪贴板（登记缺口不变）。
- Replay：`d02-original-text-kbd-chords.mjs`（15 钉）；
  `d02-original-text-keymap.mjs` 重锚至 2061。
