# ADR-1071：定位元素 + 向量适配

## 状态

已接受（Phase 1127）。

## 决策

- `xwc` = 定位元素 `{qo5 opId, g2c items, long pos}`；
  `ywc` = `{Integer, a()→qo5}` 基。
- `g2c extends hvd` = `f2c` FB 表向量→List 懒绑适配
  （`d`count/`e`绑读）。

## 依据

wire f2c → g2c List → xwc positioned → 应用记录链路。

## 后果

Harmony 序列元素 = `{id, items, pos}`；items 懒绑 List 暴露。
