# ADR-1041：载荷工厂两段式 + uq9.q 绑定

## 状态

已接受（Phase 1097）。

## 决策

Harmony op→载荷解码 = `z5c.x`：序位→`new X()` 空表 →
`uq9.q(payload)` 绑 op 的 FlatBuffers 缓冲；NONE/default
fail-loud（`rgc.b`/`o14.t`）。

## 依据

序位 switch + `uq9Var.q(l2dVar)` 绑定 + 两路 fail。

## 后果

Harmony 解码 = 构造+绑定两段；空载荷/newtype 经 `q` 定位。
