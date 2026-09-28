# ADR-0908 — `zq9` 写侧：类→haa 逆映射 + Op 信封写器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `zq9.a` = 30 项 KClass→haa 映射（**ee8=MODIFY_PDF_FIELD**
  订正 919）；`b` = 逆查 + rgc.b fail-loud。
- `e` = 7 字段信封写器：payload 先经 `ree.a` 序列化，
  f0=id(req)、f1=clientTime、f2=serverTime、f3=audioTime、
  f4=payloadType byte、f5=payload(req)、f6=transientInteraction；
  `z(iN,4)`+`z(iN,14)` 双 required——与 905 读侧全镜像。
- `zq9.a(qo5,cee,j,xgb)` = op 工厂；`c` = z5c.x 别名。

## Harmony 决策

写侧字段序/required/逆映射/fail-loud 等价镜像。

## Parity 状态

等价。

## 验证

- `d02-zq9-envelope-writer.mjs`：47/47 通过。
- 全量 Replay 837 文件绿，见 Phase 964 提交。
