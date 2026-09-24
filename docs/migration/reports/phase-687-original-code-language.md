# Phase 687 — 原版代码块语言选择（SetProgrammingLanguage）移植

## 范围

`h32`/`l32` 格式行的最后一个段落级字段——CODE_BLOCK 的
programmingLanguage——补进 `TextBlockOverlay`；并回补 P684 的种子缺陷
（无段落 run 路径漏 seedCharStyles，仅含字符样式的块提交时丢样式）。

## 原版行为（证据见 phase-687 evidence）

- `cve.java`：`bte` 语言项 → `m(new k5a(str))`（k5a=
  SetProgrammingLanguage 字段级 op）；`str===rs1.c.a('plaintext')` 映射
  `null`=清除字段；code-block 切换路径 `m(new m5a(fy2Var),
  new k5a(...))` 同包携语言上下文。
- `rs1.d`：27 语言表（bash…typescript，plaintext 为哨兵项）。
- 字符串：`ui_text__programming_language` + `ui_text__lang_*`。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `CODE_LANGUAGES` 常量表镜像 `rs1.d` 27 项（id + 显示名）。
  - `@State caretCodeLanguage`（'plaintext' 缺省）；`refreshCaretCodeLanguage`
    挂进 seed/selection/toggle 三处刷新点。
  - `setCodeLanguage(lang)`：字段拷贝同 `toggleDecoratorStyle`；
    `lang==='plaintext'` 不写字段（原版 null 语义=清除）；空对象条目删除
    保持 canonical。
  - `buildCodeLanguageMenu(): MenuElement[]` 27 项；
    `caretDecoratorStyle === 5` 时语言按钮出现（按钮文本=当前语言名），
    `bindMenu` 承载。
- 无新增字符串（按钮显示语言名本身，无需翻译键）。

## 同时修复（P684 回补）

- `seedParagraphStyles` 早退分支（`runs.length === 0`）漏调
  `seedCharStyles()`：仅含字符样式的文本块编辑提交时丢全部
  characterStyleRuns——已回补并加 fixture 钉（两路径均调用）。

## 验证

- Replay：`d02-original-code-language.mjs` 18 项全绿；lease-bound
  enabled 计数 16→17。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 限制

- 语言字段已随元素持久化并可被 CRDT 读侧解码；语法高亮渲染仍属
  ADR-0648 登记缺口（renderer 只画代码块底带，不做 token 着色）。
- 沿用 ADR-0648/0650 其余登记差异。
- 语言按钮为文本形态（当前语言名），非原版图标+下拉样式。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `docs/migration/replays/d02-original-code-language.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
