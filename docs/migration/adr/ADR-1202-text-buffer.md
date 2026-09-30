# ADR-1202：文本缓冲（gap-buffer+TextEditBuffer）

## 状态

已接受（Phase 1258）。

## 决策

`o7a` gap-buffer+`dle` Appendable+`ele` 钳位+`jqe`
packed range → Harmony 自研 CharSequence 缓冲+
TextRange。

## 理由

`o7a`=gap-buffer（`a`=char[] 拷贝 replace）；`dle`=
`Appendable`+`ele`/`o7a`/`jqe`/`rnh`；`ele`=不可变
文本+`rh8.A` 钳位；`jqe`=packed long —— 文本缓冲。

## 后果

Harmony 文本缓冲 = 自研缓冲+TextRange —— 编辑
语义保真。
