# Phase 696 — 原版空装饰段 Enter + 列表段 Tab（fm7.g/fm7.h）Evidence

## 范围

把原版富文本编辑器的两个段落级键行为移植到 Harmony 文本块
编辑覆盖层：空装饰段上的 Enter（退格装饰/降级）与列表段上的
Tab（缩进）。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/fm7.java` —— `g()`（Enter）

```java
public final void g() {
    uub uubVarF = this.c.F();          // 当前 selection
    ti3 ti3Var = uubVarF.e;
    jtc jtcVar = uubVarF.d;
    Integer numH = l8j.h(ti3Var, jtcVar);
    if (numH != null) {                // 空列表段 → indent level
        if (numH.intValue() > 0) {
            o(ys2.P(new h5a(-1)));     // 减一级缩进
            return;
        }
        c();                           // indent==0 → clearDecoratorOnCursorParagraph
        return;
    }
    if (l8j.i(ti3Var, jtcVar)) {       // 空引用/代码段
        c();                           // 清装饰
    } else {
        l("\n", null);                 // 插入换行
    }
}
```

### 2. `l8j.java` —— 判定条件

- `h()`：`qi3.c()`（段内容全为 `\n` = 空段）**且** `n4c.x(i)`（装饰为
  BULLET/NUMBER/CHECK_BOX）→ 返回 `cmfVar.I & 255`（indent level）。
- `i()`：`qi3.c()` 且 `n4c.w(i)`（BLOCK_QUOTE/CODE_BLOCK）。
- `j()`：`n4c.x(i)`（列表段，**不要求空段**）。

### 3. `n4c.java`

```java
w(fy2) = BLOCK_QUOTE | CODE_BLOCK
x(fy2) = BULLET | NUMBER | CHECK_BOX
```

### 4. `fm7.h()`（Tab）

```java
if (l8j.j(...)) {             // 光标段为列表装饰
    o(ys2.P(new h5a(1)));     // 缩进 +1
} else {
    l("\t", null);            // replaceSelectedText("\t")
}
```

### 5. `fm7.c()` —— `clearDecoratorOnCursorParagraph` op

## Harmony 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| Enter 键 → `fm7.g()` | `TextArea.onWillInsert`：`insertValue==='\n'` 时走 `onWillInsertText`，返回 `false` 拦截插入 |
| 空列表段 Enter + indent>0 → `h5a(-1)` | `adjustIndentLevel(-1)` |
| 空列表段 Enter + indent==0 → `c()` | `clearParagraphDecorator(p)` |
| 空引用/代码段 Enter → `c()` | 同上（decorator 4/5） |
| Tab → `fm7.h()` | `onEditorKeyEvent` `keyCode===2049`(KEYCODE_TAB) → `handleTabKey()` |
| 列表段 Tab → `h5a(+1)` | `adjustIndentLevel(1)` |
| 非列表 Tab → `l("\t")` | draftText 选区替换 `'\t'` + `adjustCharRunsForEdit` + `caretPosition(s+1)` + `onDraftChange`（同 confirmLink 替换管线） |
| `clearDecoratorOnCursorParagraph` | `clearParagraphDecorator`：清 `decoratorStyle` + `programmingLanguage`（code 装饰清除时语言字段一并清除），其余字段保留 |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`

## 验证

- `docs/migration/replays/d02-original-list-enter-tab.mjs`：
  23 项静态钉全绿。
