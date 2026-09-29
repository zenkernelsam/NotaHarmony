# ADR-0961 — nr1 同步引擎方法图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `nr1` = 9 依赖同步引擎：oq1/nce/ssf/qr1/jl3/sxa/
  v2f + 双 Mutex + LinkedHashMap + 三 sfb Flow。
- 方法图：`d/e`=DAO/DB 访问器，`a`=zp1 插入事务，
  `b`=上传 suspend，`g`=jq1 per-note 查询，
  `f`=dr1 tick，`c`=Flow 收集，
  `i`(761-inst)/**`j`(8622-inst)** 巨型协程
  （反编译失败 stub——主同步状态机）。

## Harmony 决策

ArkTS async 状态机重写；`i`/`j` 精确语义部分推断
——按上游 API + 下游 Room 写的可证契约重构。

## Parity 状态

结构等价；主状态机标注"部分推断"。

## 验证

- `d02-sync-engine-map.mjs`：10/10 通过。
