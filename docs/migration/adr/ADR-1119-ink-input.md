# ADR-1119：墨迹输入层（预测 + 手势分类 + 触摸）

## 状态

已接受（Phase 1175）。

## 决策

- `bi8`=`MultiPointerPredictor`（per-pointer 预测下一
  触控位置，降墨迹延迟）→ Harmony `TouchEvent` 预测：
  Harmony 提供 `getHistorical`/`touchPredictor` 或自研
  外推 —— **必须保留预测以达低延迟墨迹**。
- `iqa` 触控分类归一（双指扫 3/捏合 5/button/meta→
  动作枚举）→ Harmony 手势识别 + `toolType`。
- `cj7` OnTouchListener → Harmony `onTouch`。

## 理由

`SparseArray` per-pointer + `a(ev)/b()→ev` 预测 +
`getClassification` 3/5 + `getTapTimeout`。

## 后果

Harmony 墨迹输入 = TouchEvent 流 + 指针预测 +
手势分类 —— 低延迟需预测层；手掌/双指映射对齐。
