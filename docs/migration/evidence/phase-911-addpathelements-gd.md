# Phase 911 证据 — `gd` = `AddPathElements`

## 目的

墨迹路径追加 op 载荷实名（870 ink 族第三表）。

## `gd` = `AddPathElements`（toString 实证）

`AddPathElements(ink=, encodedCenterPathElements=,
encodedCenterPathEstimatedElements=)`

## accessor→字段图

| 访问器 | c(N) | 字段 | 类型 | 语义 |
|--------|------|------|------|------|
| `j()` | c(4) | f0 | `qo5` | **ink**（单目标，非向量） |
| `a()` 内 | c(6) | f1 | 元素向量 | **encodedCenterPathElements** |
| — | c(8) | f2 | 元素向量 | **encodedCenterPathEstimatedElements** |

- `zq9` 注册：`gd.class → haa.ADD_PATH_ELEMENTS`。
- `a()` 校验：经 `di7` 迭代器 + `ldj.I2` 逐元素
  检查路径编码合法性。

## 与 wd8 对照

`gd.j()` 单 `qo5` vs `wd8.B(qo5,int)` 参数化向量——
追加 op 只命中一条墨迹，修改 op 可命中多条。

## Harmony 核对

`OriginalAddPathElements*`/ink op 编码器对齐：
单目标 qo5 + 双路径向量（实值 + 估计值）。

## 结论

870 ink 族三表（CreateInk/ModifyInk/AddPathElements）
读侧全部实名闭合。
