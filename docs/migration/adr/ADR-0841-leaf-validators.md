# ADR-0841 — 叶子校验体 + `vy7` TBLR 序 + `ymf`=UShort

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `k3a.a()`：纸色 alpha 必须 0xFF（`c()&255<255` 报错）。
- `vy7.a()`：四边非负 + 逐边有限性；**字段序 TBLR**：
  top@+0(f)、bottom@+4(c)、left@+8(d)、right@+12(e)。
- `qed.a()`=ddg.i；`fqa.a()`=ddg.h 委托。
- `ymf` = Kotlin UShort 值类（vt9 schemaVersion 类型；
  与 mmf=UInt 同构）。

## Harmony 决策

纸色 alpha 门、边距 TBLR 序、UShort 无符号读取对齐。

## Parity 状态

等价（校验体实名 + 字段序钉死 + 值类家族补全）。

## 验证

- `d02-leaf-validators.mjs`：13/13 通过。
- 全量 Replay 770 文件绿，见 Phase 897 提交。
