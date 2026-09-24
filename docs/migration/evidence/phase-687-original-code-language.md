# Phase 687 — 原版代码块语言选择（SetProgrammingLanguage）Evidence

## 范围

把原版代码块（CODE_BLOCK 段落）的编程语言选择移植到 Harmony 文本块
编辑覆盖层：`bte` 语言项 → `k5a` 字段级 op。同时回补 Phase 684 的一个
种子缺陷。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— 派单（L216-235）

```java
if (nueVar.equals(ate.a)) {          // CODE_BLOCK 切换（fy2.5）
    o(fy2.CODE_BLOCK);
    return;
}
...
if (nueVar instanceof bte) {          // 语言选择项
    String str = ((bte) nueVar).a.a;  // rs1 语言 id
    if (str.equals(rs1.c.a)) {        // 'plaintext' 哨兵
        str = null;
    }
    if (!ba6.o(str, this.W)) {
        this.W = str;
        xj2.A(h(), null, null, new wsc(23, ef2Var, this, str), 3);
    }
    m(new k5a(str));                  // SetProgrammingLanguage op
}
```

另 L424：`m(new m5a(fy2Var), new k5a((fy2Var != fy2Var2 || z) ? null : this.W))`
——CODE_BLOCK 段落样式 op 与语言 op **同包下发**，切到 code block 时保留
既有语言上下文。

### 2. `sources/defpackage/k5a.java`

`k5a implements n5a`，单字段 `String a`，`toString =
"SetProgrammingLanguage(language=...)"` —— 语言字段级样式 op。

### 3. `sources/defpackage/rs1.java` —— 语言表

- `rs1.c` = `new rs1("plaintext", R.string.ui_text__lang_plaintext)` ——
  **哨兵**：选中 plaintext → `str = null` → 清除 programmingLanguage。
- `rs1.d` = 27 项列表：bash, c, cpp, csharp, css, go, haskell, java,
  javascript, json, kotlin, lua, markdown, markup, matlab, objectivec,
  ocaml, php, **plaintext**, python, r, racket, ruby, rust, sql, swift,
  typescript。
- `rs1.e` = id→rs1 反查 LinkedHashMap。

### 4. 字符串

`ui_text__programming_language`（选择器标题）、`ui_text__lang_*`（各语言
显示名，如 `lang_plaintext`="Plain Text"、`lang_cpp`="C++"）。

## Harmony 现状（Phase 687 之前）

- `RichTextParagraphStyle.programmingLanguage?: string` 字段存在；
  `OriginalInsertTextOperation`/`OriginalLocalCheckboxMutation`/
  `OriginalRichTextStyleOperation`/`NotePackageSpec` 全部支持该字段的
  克隆/编解码。
- `toggleDecoratorStyle` 对 decorator=5 保留 `programmingLanguage`。
- 缺口：**无 authoring 入口**。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `bte` 语言项 | `bindMenu` 27 项菜单（仅 `caretDecoratorStyle === 5` 时出现） |
| `k5a(str)` 字段级 op | `setCodeLanguage(lang)` 写 `draftStyles.programmingLanguage` |
| `rs1.c.a` plaintext → null | `lang !== 'plaintext'` 才写字段——plaintext 显式清除 |
| `br2`-like 当前语言态 `this.W` | `@State caretCodeLanguage`（plaintext 为缺省显示） |
| 语言显示名 `ui_text__lang_*` | `CODE_LANGUAGES` 表内 label（Bash/C++/C#/Objective-C/Plain Text 等） |

## P684 回补修复

`seedParagraphStyles` 的 `runs.length === 0` 早退分支漏调
`seedCharStyles()`——仅含字符样式（无段落 run）的文本块编辑提交时会丢
全部 `characterStyleRuns`。本期修复：该分支同样调用 `seedCharStyles()`
并初始化 `caretCodeLanguage`。fixture 已钉两路径。

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`

## 验证

- `docs/migration/replays/d02-original-code-language.mjs`：18 项静态钉全绿。
