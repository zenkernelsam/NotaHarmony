# Phase 1255 证据 — pm6/xl6/ysc 键盘快捷键表

来源：`defpackage/{pm6,om6,xl6,ysc,ek8,qv2,jl4}.java`。

## `xl6` = 48-命令 key-command 枚举

```java
LINE_RIGHT,UP,DOWN,CENTER,PAGE_UP,DOWN,HOME,END,
COPY,PASTE,CUT,DELETE_PREV_CHAR,...,DESELECT,
NEW_LINE,TAB,UNDO,REDO,CHARACTER_PALETTE
final boolean I;   // requires-editable 标志
xl6(boolean z);    // 需编辑=true
a()→I;
```

- `I=true`（PASTE/CUT/DELETE_*/NEW_LINE/TAB/UNDO/REDO/
  CHARACTER_PALETTE）= **需可编辑**；
- `I=false`（导航/SELECT_*/COPY/DESELECT）= 无需编辑。

## `pm6`/`om6` = 键映射（keyCode→xl6）

`pm6.a` = `om6` keymap holder —— KeyEvent→`xl6` 查表。

## `ysc` = 命令执行上下文

```java
final class ysc {
    pdf a;              // 文本会话
    wpe b;              // 文本布局
    boolean c; float d; // editable + lineHeight
    jl4 e;              // 滚动状态
    ele f; cvc g; long h; u4g i; String j;
    a()/b()              // 命令执行
}
```

## 语义

`vle.H(KeyEvent)` → `pm6` keymap → `xl6` 命令 → `ysc`
上下文执行 —— **全键盘快捷键表**（48 命令：`I` 标志
门控 editable）。

## Harmony 决策

KeyEvent→命令表 → Harmony `onKeyEvent`+命令 enum+
editable 门控 —— 快捷键语义保真。

## 产出

- fixture `d02-keymap.mjs`（10 断言）。
- ADR-1199；中文报告。
