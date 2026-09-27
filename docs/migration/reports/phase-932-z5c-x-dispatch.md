# Phase 932 报告 — z5c.x 主载荷分发开关

## 范围

`z5c` 剩余协议方法审计：`x`/`y`。纯审计。

## 原版发现

- `z5c.x(uq9)` = **主载荷物化开关**：单 switch
  映射全部 31 序数→读类 + `q()` 初始化；
  case 0 NONE 硬抛错。对 zq9/haa 注册的
  **权威交叉验证**——逐项一致。
- `z5c.y(qo5,x09)` = 内容高度助手 `u3c`
  （vy7 边距扣页高；xhe→cie 文本块查找）——
  布局域非线型。

## 产出

- 证据：`phase-932-z5c-x-dispatch.md`
- Fixture：`d02-z5c-x-dispatch.mjs`（35/35）
- ADR-0876；全量 Replay 805 文件绿。
