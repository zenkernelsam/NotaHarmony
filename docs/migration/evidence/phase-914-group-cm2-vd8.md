# Phase 914 证据 — `cm2`=`CreateGroup` / `vd8`=`ModifyGroup`

## 目的

分组 op 二表实名（871 shape/group 族收尾）。

## `cm2` = `CreateGroup`（toString 实证）

`CreateGroup(members=)` —— 单字段：

| 访问器 | c(N) | 类型 | 语义 |
|--------|------|------|------|
| `j(qo5,i)`/`lv2.P` | c(4) | `qo5[]` 结构向量 | **members**（8B 元素，`(i*8)+f(v)` 索引） |

- 校验：`"Cannot create a group with 0 members"`。
- 注册：`zq9` → `haa.CREATE_GROUP`。

## `vd8` = `ModifyGroup`（toString 实证）

`ModifyGroup(group=, members=)` —— 双字段：

| 访问器 | c(N) | 类型 | 语义 |
|--------|------|------|------|
| `j()` | c(4) | `qo5` 结构 | **group**（必填 `o14.i`） |
| `k()`/`l(qo5,i)`/`lv2.Q` | c(6) | `qo5[]` | **members** 新成员集 |

- 注册：`zq9` → `haa.MODIFY_GROUP`。

## 要点

- qo5 为 8B 内联结构向量元素（`(i*8)+f(vec)` 寻址
  实证）——非间接表引用。
- CreateGroup 极简：仅成员集；ModifyGroup 为
  {目标组 required, 新成员集}。

## Harmony 核对

分组 op 编码对齐：qo5[] 内联结构向量 + 必填断言。

## 结论

871 shape/group 族四表（ao2/le8/cm2/vd8）读侧全闭。
