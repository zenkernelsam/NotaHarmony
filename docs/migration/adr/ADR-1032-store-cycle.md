# ADR-1032：因果存储 = gja↔hja builder↔快照环

## 状态

已接受（Phase 1088）。

## 决策

Harmony 因果存储三层：

- `ija` = 只读物化视图（应用读）；
- `gja extends lk6` = 可写存储 builder（`build()→hja`）；
- `hja extends ik6` = 不可变快照（`builder()→gja`，
  协变 put）。

与实体层 `xy3`/`yy3` 环同构。

## 依据

`gja`/`hja` 接口互指 + `lk6`/`ik6` 可变/不可变标记。

## 后果

Harmony：写经 `gja`、物化经 `ija`、快照经 `hja`。
