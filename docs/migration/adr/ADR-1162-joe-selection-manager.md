# ADR-1162：joe = TextFieldSelectionManager

## 状态

已接受（Phase 1218）。

## 决策

`joe` 文本域选区管理（`zn9` Offset.Unspecified 手柄
位 + `mse` HandleState + `r95` 手柄型 + `tr1` haptic
+ `A` IME 监视）→ Harmony 选区管理组件 + `vibrator`
+ IME 会话时序。

## 理由

实名枚举：`mse`{None,Cursor,Selection}、`r95`{Cursor,
SelectionStart,SelectionEnd}、`zne`{None,Touch}；
`zn9(0x7FF8000000000000)`=Offset.Unspecified；
`k6f.a`→`eje`/`tqd` IME 会话。

## 后果

Harmony 选区管理 = 手柄位置态+类型+拖动+haptic+
IME 监视 —— 语义对齐 Compose SelectionManager。
