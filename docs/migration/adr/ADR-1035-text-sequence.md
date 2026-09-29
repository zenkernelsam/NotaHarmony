# ADR-1035：文本序列 CRDT 内部类型

## 状态

已接受（Phase 1091）。

## 决策

Harmony 文本序列 = `hr5` 可变锚点 + `swc` 树导航器
（`d` 派生锚/`e` 范围/`getParent`）+ `s3c` 样式片段 +
`gxc` 线锚点。

## 依据

`hr5`{site,seq,…} + `swc` 导航签名 + `s3c` 双样式集。

## 后果

Harmony 插入经 `swc.d` 派生 fractional 锚；片段 `s3c`。
