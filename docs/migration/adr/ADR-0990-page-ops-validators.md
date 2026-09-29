# ADR-0990 — 页面操作载荷与 ddg 共享校验库

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ln2` CreatePage/`ge8` ModifyPage 字段布局与 PDF 页数
  一致性校验；`nz9`=PageBackground{paper,pdf,rotation,
  size,margins}，`m2d`=SetPageBackground，`sw9`=PDF 引用。
- `ddg` = 共享校验库：触控笔点（po4）、标量有限性、
  PDF cropbox、背景边距/旋转、尺寸（qed）非负。

## Harmony 决策

页操作校验逐条保留；`ddg` 建模为共享 OpValidators。

## Parity 状态

等价。

## 验证

- `d02-page-ops-validators.mjs`：12/12 通过。
