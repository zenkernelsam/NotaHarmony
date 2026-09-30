# ADR-1148：t76 消费方（Flow 收集器 + 对账 + 动效）

## 状态

已接受（Phase 1204）。

## 决策

- `ol4` FlowCollector/`ef2` → Harmony 事件订阅回调。
- `ls` MotionEvent↔StrokeInput 对账 → Harmony 笔迹
  输入一致性校验。
- `ot3` Material 动效（TweenSpec 120/150ms +
  cubic-bezier 0.4,0,0.6,1）→ Harmony `curves`
  + 对应时长动画。
- `em1`/`j5j` Compose 框架层 → 不迁移（ArkUI 代替）。

## 理由

`ol4.emit`/`ls` StrokeInput 对账告警 + link ClipData +
`ot3` `vhf(120/150,iq2(0.4,0,0.6,1))` 规格。

## 后果

Harmony 手势消费 = 订阅回调 + 笔迹对账校验 +
ArkUI 动画令牌（材质缓动对齐）。
