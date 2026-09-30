# ADR-1180：ww0 触觉强度动画器

## 状态

已接受（Phase 1236）。

## 决策

`ww0` 事件栈→权重（rj5/zo4/mn3=0.08/0.1/0.16）+
`vhf` tween（45/150ms）渐进触觉 → Harmony `vibrator`
+自研 tween 权重映射。

## 理由

`ww0` 维护活跃事件栈（down 入/end 出配对），栈顶→
触觉权重，tween 动画 —— 触觉压力随工具/手势分级
平滑过渡。

## 后果

Harmony 触觉 = vibrator 强度 + tween —— 触觉分级
语义保真。
