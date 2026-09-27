# ADR-0832 — `k3a` 纸面配置六字段

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `k3a` = `C(6)`：`{template:n3a@0, spacing:Float@1(0),
  flag:Bool@2, flag:Bool@3, color:hu1@4(z5c.P), cmf:byte
  enum@5}`——`fag.o0` 实证；两布尔写期间 `aVar.l` 模式标记。
- `fag.n0` = 序列化委托（k3a.k/n/l/m/j/o 六访问器）。
- `fag.k` = 存根工厂；a79.Q 掩码 111（bit0+1+2+5+6）=
  仅色显式、其余默认——再证省略参数序号模式。
- `tu1.a` = `pce` 惰性提供者（ra(13)）→默认纸色；
  `cmf` = 字节值类枚举；`n3a`=LINES/DOTS/GRID。

## Harmony 决策

k3a 六槽 ↔ `PageBackgroundModel`/`validateOriginalPaper`；
hu1 色 ↔ 颜色结构写；tu1 默认色 ↔ 默认纸配置。

## Parity 状态

等价（纸面线格式闭合）。

## 验证

- `d02-k3a-paper-config.mjs`：16/16 通过。
- 全量 Replay 与双 HAP 构建见 Phase 888 提交。
