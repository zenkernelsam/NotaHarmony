# ADR-0869 — `lv2` 物化器族

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `lv2.*` = 各表共用的向量→List 物化静态族：
  `len→m18.S() builder→逐位访问器→m18.E()` 不可变
  List；`hw3.I` 空表常量；`di7` IntRange 迭代器；
  字节向量经 `ei7`/`nl8` 包装。
- 覆盖：路径向量（dm2/wd8）、cxc[] 位置集、
  qo5[] 目标集、ie8[]、uq9[]（r29/vt9）、
  s83 墓碑×4、segmentation。

## Harmony 决策

解码侧对齐：长度门→逐位读取→不可变 List。

## Parity 状态

等价（读侧共享通道模式）。

## 验证

- `d02-lv2-materializers.mjs`：23/23 通过。
- 全量 Replay 798 文件绿，见 Phase 925 提交。
