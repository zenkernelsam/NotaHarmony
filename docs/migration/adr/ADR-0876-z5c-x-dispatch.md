# ADR-0876 — `z5c.x` 主载荷分发开关

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`z5c.x(uq9)` = 应用侧载荷物化开关：按 `m()`
（haa 序数）`new` 对应读类并 `q()` 初始化——
31 个 case 与 haa 枚举/zq9 注册逐项一致。
case 0（NONE）硬抛错（`rgc.b` + throw），
与 `m()` 枚举回退 NONE 形成读端容忍/分发端
失败关闭的对照。

`zgb`/`vq9`/`sdf`/`r29` 不在开关内——信封层表。

## Harmony 决策

载荷分发按同一序数表；NONE 载荷失败关闭。

## Parity 状态

等价（权威交叉验证通过）。

## 验证

- `d02-z5c-x-dispatch.mjs`：35/35 通过。
- 全量 Replay 805 文件绿，见 Phase 932 提交。
