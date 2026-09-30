# ADR-1184：t76 事件分类学全景

## 状态

已接受（Phase 1240 里程碑）。

## 决策

`t76` start↔end 配对事件总线（含 1:2 终态 mn3/fwa）
→ Harmony `onTouch`/`gesture` 回调 + 自研事件栈。

## 理由

`t76` 全景：`rj5`↔`sj5`/`zo4`↔`ap4`/`ll3`↔`ml3` 1:1；
`mn3`↔`nn3`+`ln3`、`fwa`↔`gwa`+`ewa` 1:2 fire/cancel —
— 手势生命周期驱动触觉/状态机/会话边界。

## 后果

Harmony 手势事件 = onTouch/gesture+事件栈 ——
配对语义保真。
