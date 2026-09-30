# Phase 1210 证据 — vle.H 键命令层（xl6 48 命令 + pm6/ysc）

来源：`defpackage/{vle,xl6,pm6,ysc,cq,jl4,ek8,qv2}.java`。

## `vle.H(KeyEvent)`（jm6）结构

```java
long jB = cq.b(keyEvent.getKeyCode());       // key 打包
if (gm6.f(keyEvent)==1) {                    // DOWN
    ek8 keymap = pg0.K;
    if (keymap!=null && keymap.a(jB)) { keymap.e(jB); return true; }
} else {
    Integer dead = ((qv2)pg0.J).a(keyEvent); // 死键组合
    xl6 cmd = pm6.a.k(keyEvent);             // ← 键映射表
    if (cmd==null || (cmd.I && !z3)) return false;  // I=需可编辑
    float scrollX = mv6.J(...).e();          // 视口 x
    ysc ctx = new ysc(pdf,wpe,shift,scrollX,jl4);
    switch (cmd.ordinal()) { case 0..46: }   // 每命令→编辑动作
}
```

## `xl6` = 48 键命令枚举（`I` = 需可编辑）

| 簇 | 命令 |
|---|---|
| 导航 17 | LEFT/RIGHT_CHAR, LEFT/RIGHT_WORD, NEXT/PREV_PARAGRAPH, LINE_START/END, LINE_LEFT/RIGHT, UP, DOWN, CENTER, PAGE_UP/DOWN, HOME, END |
| 剪贴板 3 | COPY, **PASTE***, **CUT*** |
| 删除 6* | DELETE_PREV/NEXT_CHAR, DELETE_PREV/NEXT_WORD, DELETE_FROM_LINE_START, DELETE_TO_LINE_END |
| 选择 18 | SELECT_ALL, SELECT_LEFT/RIGHT_CHAR, SELECT_UP/DOWN, SELECT_PAGE_UP/DOWN, SELECT_HOME/END, SELECT_LEFT/RIGHT_WORD, SELECT_NEXT/PREV_PARAGRAPH, SELECT_LINE_START/END, SELECT_LINE_LEFT/RIGHT, DESELECT |
| 插入 2* | NEW_LINE, TAB |
| 历史 2* | UNDO, REDO |
| 特殊 | CHARACTER_PALETTE |

（*=I=true 需编辑态；导航/选择/复制 false）

## `ysc` = 命令执行上下文

`{pdf doc, wpe 文本块, boolean shift, float scrollX,
jl4 滚动态, ele 编辑, cvc 范围, String j}` — 每条命令
在 doc+selection+scroll 上求值（`b()` 方向判断等）。

## 支持件

- `cq.b(int)→long` = Key 打包；`ek8` = 附加键表；
- `qv2` = 死键组合 map；`jl4` = 滚动偏移态；
- `pm6` = 平台键映射（Ctrl/Cmd+key→xl6）。

## Harmony 决策

`xl6` 48 命令 → ArkTS 键命令枚举 + `pm6` 键映射 →
`keyCode`+ctrl/shift 查表；`ysc` 上下文 → 编辑器
选择/滚动执行器。

## 产出

- fixture `d02-vle-keycommand.mjs`（10 断言）。
- ADR-1154；中文报告。
