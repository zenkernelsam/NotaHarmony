# ADR-1023：实体→be5 解析器（ba6.R）

## 状态

已接受（Phase 1079）。

## 决策

Harmony 实体→变换源解析 = `ba6.R`：tombstone 短路（`K`）
→ 主表 ly3→be5 → `s06`/`m4d`/`ly3` 类别表回退链。

## 依据

5-map 签名 + `K` tombstone + `instanceof be5` + spec
`m4d`/`s06` 也作变换源。

## 后果

Harmony 删除实体不参与变换；spec 初始态可读包围盒。
