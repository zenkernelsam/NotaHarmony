# ADR-1076：序列树 DFS 遍历 + 码点换算

## 状态

已接受（Phase 1132）。

## 决策

- `njj.t` = 迭代 DFS：`Q` 锚→节点、`m` parent→child、
  `p` 子表、`u` 索引、`vz3` 栈帧 + `ix4` 回调/节点。
- `n4c.a` = 码点→char-index（lz0/ry1 短路 +
  `offsetByCodePoints`）。

## 依据

root→anchor DFS 找插入点；UTF-16 码点偏换算。

## 后果

Harmony：栈式 DFS + 访问者回调；码点→index 用
`String.codePointCount` 等价。
