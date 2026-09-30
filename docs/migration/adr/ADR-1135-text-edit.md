# ADR-1135：文本编辑 undo 记录（ele/dle）

## 状态

已接受（Phase 1191）。

## 决策

`dle`=`Appendable` 累积 → `ele`=`CharSequence` 编辑记录
`{List I,List J,CharSequence K,long L}` → `nnf` op 栈 →
Harmony 文本编辑记录 + Appendable 等价累积 → undo op。

## 理由

`ele implements CharSequence`{2 List+text+ts} + `dle
implements Appendable`{ele,f76,o7a,rnh} + `qoe` 会话
`b(dle)`/`e(ele,ele)`。

## 后果

文本编辑 = CharSequence 记录（范围+内容+ts）可逆；
Harmony 用编辑记录 struct + 累积器。
