# ADR-1026：页裁剪键 + 时间戳分工

## 状态

已接受（Phase 1082）。

## 决策

- 页裁剪表以 `tz9{cxc}` 页引用为键（`do6.i`）。
- 时间戳：`fsi.J` = serverTime?:clientTime（兜底），
  `nti.y` = 仅 serverTime→`xgb`（可空严格）。

## 依据

`map.get(tz9)` + `nti.y`/`fsi.J` 分支。

## 后果

Harmony 页裁剪按页引用索引；寄存器时间戳分兜底/严格两式。
