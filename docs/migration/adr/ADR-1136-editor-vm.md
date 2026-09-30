# ADR-1136：编辑器 ViewModel + undo apply

## 状态

已接受（Phase 1192）。

## 决策

`vle` = 笔记编辑器 ViewModel（`n73/od8/j73`）——归一
输入 `iqa`→编辑 op→`nnf` undo 栈；`canUndo` 守卫 +
`dve{pos,text,len,ts}` 逆 op + `dle.c` 逆 apply →
Harmony 编辑器 `@Observed` VM + op 逆变换 + `canUndo`
状态。

## 理由

`vle extends n73 implements 11 ifaces` + `A(iqa,jqa)` +
`nnf`/`ekd`/`au1.C1`/`dle.c` + `canUndo` 守卫串。

## 后果

编辑器 VM：输入→编辑 op→undo 栈（逆 op apply）；
Harmony MVVM + op 逆变换 + canUndo 守卫对齐。
