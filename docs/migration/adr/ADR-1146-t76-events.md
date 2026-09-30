# ADR-1146：t76 手势事件族 + 触觉栈

## 状态

已接受（Phase 1202）。

## 决策

`t76` 12 实现手势事件（down 标记 + 包装结束 +
`hwa` 定时子族）→ ArkTS 判别联合手势事件；
`ww0`/`e71` add/remove 栈顶手势→触觉权重
（0.08/0.10/0.16）→ Harmony `vibrator` 强度映射。

## 理由

`sj5{rj5}`/`ap4{zo4}`/`nn3|ln3{mn3}`/`ml3{ll3}`/
`gwa|ewa{fwa}` 包装对 + `ww0` 栈顶 `0.08f/0.10f/0.16f`
权重 + `fwa{long}` 时间戳 + 8 消费方 instanceof 分发。

## 后果

Harmony 手势输入 = down/end 配对栈 + 栈顶手势→
haptic 强度 —— 与 Phase 1197 stylus-haptic 偏好衔接。
