# Phase 684 — 原版字符样式（Bold/Italic/Underline/Strikethrough）移植

## 范围

P681/P683 落地了段落级 authoring（quote/code + 三种列表装饰）；本期把同一
格式行的**字符级**样式四件套——Bold / Italic / Underline / Strikethrough
——补进 `TextBlockOverlay`，并把提交管线扩为双 run 数组贯通。至此原版
`h32`/`l32` 格式行的核心样式项全部落地（link/indent/上下标/高亮/字体
留待后续期）。

## 原版行为（证据见 phase-684 evidence）

- `cve.java` 派单：`xse`/`vte`/`mue`/`jue` → `n(new zyd(...))`，分别取反
  `br2` 的 a/b/c/d 位，写入 `zyd.a`(bold)/`zyd.b`(italic)/`zyd.c`(underline)/
  `zyd.k`(strikethrough)；`zyd` 11 字段与 `RichTextCharacterStyle` 1:1 对应，
  `null` 字段=保持——字段级增量语义。
- `l32.java` 渲染 italic/underline/strikethrough 行条目；
  `strings.xml` 含 `ui_text__bold/italic/underline/strikethrough`。
- 选区非空 → 应用到选区；折叠光标 → typing-attributes 对后续输入生效。

## Harmony 实现

- `TextBlockOverlay.ets`
  - 新增 `caretSelectionStart` + `caretChar{Bold,Italic,Underline,Strike}`
    + `draftCharRuns` + `pendingCharStyles` 状态；`seedCharStyles` 从
    `element.characterStyleRuns` 克隆种子。
  - `rangeHasCharStyle`（完全覆盖判定）、`applyCharStyle`（边界切分 +
    字段级改写 + 空洞补 run，深拷贝保留其余字段）、`normalizeCharRuns`
    （排序/去空/相邻合并）、`adjustCharRunsForEdit`（公共前后缀差分平移
    收缩 run 边界）。
  - `toggleCharStyle`：选区非空 → 覆盖态取反改写；折叠 → 翻 pending，
    `onChange` 把 pending 落地到实际插入区间。
  - 工具条新增 B/I/U/S 四枚切换钮（置于列表装饰前，对齐原版行序）。
  - `onCommit` 扩为 `(text, charRuns, paraRuns)` 三参；Done 提交后清空
    字符 draft。
- `NoteCanvasView.ets`
  - `onTextCommit` 扩为三参；`stylesDiffer` 覆盖字符 run；
    本地/非 CRDT/CRDT-preview/样式-only 四分支均以 `authored ?? existing`
    独立传递两数组——顺带修复了样式-only 分支原先把未 authored 段落 run
    置 `[]` 的隐患。
  - 覆盖层回调 3 参透传。
- 资源：`bold`/`italic`/`underline`/`strikethrough` en+zh。

## 验证

- Replay：`d02-original-character-styles.mjs` 34 项全绿；受影响既有
  fixture（lease-bound 计数 8→12、onChange/onCommit 钉、quote-code-blocks
  签名/stylesDiffer/回调钉、whitespace-commit 三参钉）同步更新通过；
  全量套件见提交记录。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）；B/I/U/S 的选区交互、pending 输入落地、
  渲染与持久化回环列入真机验证清单。

## 限制（详见 ADR-0650）

- 折叠光标 pending 在 collapsed→collapsed 移动后不清除（原版移动即失效，
  低危偏差）。
- CRDT 块样式-only 变更仍只写元素级（无 MODIFY_CHARACTER_STYLE 编码器，
  沿用 ADR-0648 登记缺口）。
- superscript/subscript/highlight/font/link 本期未覆盖。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`
- `docs/migration/replays/d02-original-character-styles.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
- `docs/migration/replays/d02-original-quote-code-blocks.mjs`
- `docs/migration/replays/d02-text-whitespace-commit.mjs`
- `docs/migration/evidence/phase-684-original-character-styles.md`
- `docs/migration/adr/ADR-0650-original-character-styles.md`
