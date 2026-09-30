# ADR-1199：键盘快捷键表

## 状态

已接受（Phase 1255）。

## 决策

`pm6` keymap+`xl6` 48-命令 enum（`I` editable 门控）+
`ysc` exec ctx → Harmony `onKeyEvent`+命令 enum+editable
门控。

## 理由

`vle.H`→`pm6`→`xl6`（48 命令，`I=true`=PASTE/UNDO 需
编辑）→`ysc{pdf,wpe,jl4}` 执行 —— 快捷键管线。

## 后果

Harmony 快捷键 = onKeyEvent+命令 enum+editable ——
快捷键语义保真。
