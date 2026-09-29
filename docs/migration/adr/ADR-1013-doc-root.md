# ADR-1013：文档根 v69 + 因果集合族

## 状态

已接受（Phase 1069）。

## 决策

Harmony 文档/页根 = `v69`：7 元数据 `fqb` 寄存器 + `e4c`
实体集 + `*ja`/`*ia` 因果集合（`ija`/`via` LinkedHashMap、
`w4`/`vz` set 基）。

## 依据

`v69` 字段全谱 + 集合族基类实现（Map/AbstractSet）——
causal-order 容器支撑实体与文本序列。

## 后果

Harmony 页模型 = 元数据寄存器 + 因果集合承载的实体/
元素；集合序由因果键决定（非插入序）。
