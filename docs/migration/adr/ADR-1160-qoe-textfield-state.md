# ADR-1160：qoe TextFieldState + wx5 undo 链

## 状态

已接受（Phase 1216）。

## 决策

`qoe`（TextEditBuffer `dle` + `a46` sink + `p6a` 态）
+ `wx5` undo 会话（`nnf` 宿主：`redo.clear` +
容量淘汰 + `dve` 推送）→ Harmony `TextEditState` +
自研逆操作 undo 栈（同语义）。

## 理由

`qoe.a` 中央应用（no-op 快路径→`e`应用→
`a46.i`sink）+ `f(true)` undo 边界 + `wx5`
`while(size>cap-1) undo.remove(0); undo.add(dve)` —
完整撤销链 `vle→pdf→qoe→wx5→nnf→dve` 闭合。

## 后果

Harmony 文本域 undo = 逆操作栈（容量淘汰+redo
清空）—— 与原版撤销语义一致。
