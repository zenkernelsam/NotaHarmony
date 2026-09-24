# Phase 686 — 原版段落缩进 ±1（Increase/Decrease Indent）移植

## 范围

`l32` 格式行行首两项——increase/decrease indent——补进
`TextBlockOverlay`，段落级缩进首次可 authoring。至此 `l32` case0-6
全部落地（行内剩余 case7+/`h32` 的 link、颜色、高亮、字体项留待
后续期）。

## 原版行为（证据见 phase-686 evidence）

- `cve.java`：`ute` → `m(new h5a(1))` 增缩进；`yte` → `m(new h5a(-1))`
  减缩进——段落级 indentLevel 增量 op。
- `l32` case0/1 为行首两项，先于 italic。
- 字符串：`ui_text__increase_indent`/`ui_text__decrease_indent`。

## Harmony 实现

- `TextBlockOverlay.ets`：新增 `adjustIndentLevel(delta)`——
  `draftStyles.get(paragraphIndexAt(caretOffset))` 光标段落粒度，
  `indentLevel = max(0, (cur ?? 0) + delta)`；字段拷贝与
  `toggleDecoratorStyle` 同模式（alignment/lineSpacing/
  writingDirection/isChecked/decoratorStyle/programmingLanguage
  全保留）；level 归 0 且无其余字段时删条目保持 canonical。
- 按钮：increase_indent/decrease_indent 按 l32 行序置于 bold 与
  italic 之间（动作钮，非切换态，沿用 Done/Cancel 朴素样式）。
- 资源：`increase_indent`/`decrease_indent` en+zh（增加缩进/减少缩进）。
- 渲染器 `indentLevel * fontSize * 36/14` 缩进此前已就绪。

## 验证

- Replay：`d02-original-indent-controls.mjs` 12 项全绿；
  lease-bound enabled 计数 14→16。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 限制

- 沿用 ADR-0648/0650 登记差异（CRDT 段落/字符样式编码器缺口、
  pending 清除时机）。
- 原版 `uz4Var.X(...)` 的可见/可用条件未全解码，按常规编辑态可见实现。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`
- `docs/migration/replays/d02-original-indent-controls.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
