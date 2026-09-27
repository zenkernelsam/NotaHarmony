# ADR-0835 — `mmf` = UInt 值类 + `xw9` 布局枚举实名

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `mmf` = Kotlin `UInt` 内联值类：`a(i)`=`i&0xFFFFFFFF`
  无符号格式化；`compareTo`=`I^MIN_VALUE` 无符号比较。
  所有包装点（pageCount/页数×3/fileSize）= **UInt32**。
- `xw9` = PDF 布局行为 byte 枚举：
  `DOWNSCALING_AND_MAX_BOX=0, DOWNSCALING_AND_CROP_BOX=1,
  FIT_AND_CROP_BOX=2`；`j7j.c` 默认 2 = FIT_AND_CROP_BOX。

## Harmony 决策

页数/尺寸字段按无符号读取；PDF 适配模式三值逐值对应
xw9；默认 FIT_AND_CROP_BOX 语义保持。

## Parity 状态

等价（值类语义与枚举值全实名对齐）。

## 验证

- `d02-mmf-uint-xw9.mjs`：14/14 通过。
- 全量 Replay 764 文件绿，见 Phase 891 提交。
