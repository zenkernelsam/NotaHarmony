# ADR-0855 — `gd` = `AddPathElements` 读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `gd` = AddPathElements：ink:qo5@0（单目标）、
  encodedCenterPathElements@1、
  encodedCenterPathEstimatedElements@2（双路径向量：
  实值 + 估计值）；`zq9` 注册 `haa.ADD_PATH_ELEMENTS`。
- `a()` 校验经 `di7` 迭代器逐元素检查路径编码。
- 单 `qo5` 访问器 vs `wd8` 参数化 `qo5[]`——追加 op
  只命中一条墨迹，修改 op 可命中多条。

## Harmony 决策

墨迹路径追加编码对齐：单目标 + 双路径向量。

## Parity 状态

等价（870 ink 族三表读侧全闭）。

## 验证

- `d02-addpathelements-gd.mjs`：8/8 通过。
- 全量 Replay 784 文件绿，见 Phase 911 提交。
