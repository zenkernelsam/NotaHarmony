# ADR-0546: 审计 3.3 混淆类定位闭环（fc0/f92/dd4/undo 深度）

## Status

Accepted, 2026-09-22.

## Context

审计缺口清单 3.3 挂了四个小定位任务，阻塞 A-15、A-17、A-19、A-07、R-32
五条目。基准源为 `decompiled_1.0.1/sources/defpackage`（审计所称
`reference/defpackage`）。

## Evidence

- `fc0` → `hc0`（`SingleAttribute`）：`a()`=altitudeAngle、
  `b()/c()`=azimuthUnitVectorX/Y、`d()`=force、`e()`=strokeWidth；
  `gc0` 为插值包装。`ke2`（ControlPoint）字段同族但编号不同。
- `f92.c(d,m,b,dv)` = `(d·m+b)/dv`；`xaa.b` 的调用参数 (1,0,1) 恒等。
- `dd4.d(d)` = `clamp(d, 2.6, 18.0)`；`ms1.java:180` 容差式 =
  `0.5/(((clamp(w·zoom,2.6,18)−2.6)/15.4)·1.5+1)/zoom`，无 Math.log。
- undo：`nnf`/`ekd`（快照态持久 List）无界；会话撤销走 `n1d.X0`→
  `tzc`/`nzc` CRDT op 回放，`tzc` 无数值深度常量（`a0`=2s 合并窗）。

## Decision

- **A-15/A-17**：确认 Harmony 已对齐（angleDiff 与 sizeFactor 同源
  altitudeAngle；散布方向用 azimuthUnitVectorX/Y + (1,0) 回退）——
  条目关闭，无代码变更。
- **A-19**：`f92.c(·,1,0,1)` 为恒等仿射，原版无最终钳制——条目关闭，
  无代码变更。
- **A-07**：公式逐字一致——条目关闭，无代码变更。
- **R-32**：原版撤销无数值上限（深度 = 会话 op 保留窗）。Harmony 保留
  128 动作 + 32MB 双预算作为有意发散（设备内存安全），条目关闭。

## Consequences

- 五条挂起 ❓/⚠️ 条目全部关闭；域1/域4 剩余真实待修项收敛到已列出的
  修复清单。
- 新增 replay 钉住容差公式、同源字段、双预算常量，防止后续回归。
