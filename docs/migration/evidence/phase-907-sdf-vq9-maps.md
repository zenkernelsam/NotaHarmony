# Phase 907 证据 — `sdf`/`vq9` accessor→偏移全图

## 目的

钉死 TransientInteraction 与 OpAck 读契约（862/861
字段级注册的精确偏移补全）。`decompiled_1.0.3`。

## `sdf` = `TransientInteraction`（toString 实证）

`TransientInteraction(interactionId=, timeout=)`：

| 访问器 | `c(N)` | 字段 | 类型 | 语义 |
|--------|--------|------|------|------|
| `l(qo5)` | c(4) | f0 | `qo5` 内联 | **interactionId**（必填） |
| `k()` | c(6) | f1 | `mmf` UInt | **timeout** |

## `vq9` = `OpAck`（toString 实证）

`OpAck(id=, timestampedOp=, nakError=, duplicate=)`：

| 访问器 | `c(N)` | 字段 | 类型 | 语义 |
|--------|--------|------|------|------|
| `k(qo5)` | c(4) | f0 | `qo5` 内联 | **id** |
| `n(uq9)` | c(6) | f1 | `uq9` 间接 | **timestampedOp** |
| `l()` | c(8) | f2 | String | **nakError** |
| `j()` | c(10) | f3 | `Boolean` | **duplicate** |

- 字段序与 861 注册一致；sdf timeout 为 UInt（mmf）。

## 读法归类

- 内联结构：`l(qo5)`/`k(qo5)`（xwd.b 直读）。
- 标量：mmf `get`、Boolean `get`。
- 间接表：`n(uq9)`（UOffsetT 随动）。

## Harmony 侧

- 瞬态交互槽 ↔ {interactionId, timeout:UInt}；
- ack 解析 ↔ OpAck 四字段（ack 层 861 已对齐）。

## 结论

sdf/vq9 读契约钉死；op 层读表族（uq9/r29/sdf/vq9/
tdf）accessor 图基本齐。纯文档+fixture 阶段。
