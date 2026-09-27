# Phase 931 证据 — 三形状定义表字段级布局

## 目的

`uf7`/`pra`/`oz8` 访问器→偏移精确钉死。

## `uf7` = `Line`（实证）

| 访问器 | 偏移 | 字段 | 类型 |
|---|---|---|---|
| `n()` | c(4) | start | fqa **必需**（"No value for (required) field start"） |
| `k()` | c(6) | controlPoint1 | fqa |
| `l()` | c(8) | controlPoint2 | fqa |
| `m()` | c(10) | end | fqa |
| `j()` | c(12) | arrowHead | `z90` 字节枚举（范围校验回退元素0） |

`z90` = **`ArrowHead{NONE=0, SINGLE=1}`**（2 值）。

## `pra` = `Polygon`（实证）

- `points` 向量 @c(4)；元素 = **fqa 8B inline 结构**
  （`i*8 + f(iC)`，越界 `"Index out of range: i,
  vector points is empty"`）；`lv2.a0` 物化 List。

## `oz8` = `NormalShape`（实证）

| 访问器 | 偏移 | 字段 | 类型 |
|---|---|---|---|
| `k()` | c(4) | type | `pz8` 字节枚举（回退0） |
| `j()` | c(6) | size | qed **必需**（"No value for (required) field size"） |

`pz8` = **`NormalShapeType{ELLIPSE=0}`** ——
原版 1.0.3 **仅椭圆一种预置形**（矩形等走 Polygon）。

## 结论

三定义表布局全钉死；两个必需字段+两枚举
（ArrowHead 2 值、NormalShapeType 单值）确认。
