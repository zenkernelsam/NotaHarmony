# ADR-1189：ll3/ml3 编辑会话边界

## 状态

已接受（Phase 1245）。

## 决策

`ll3`=session start（`vle.k0`）+`ml3{k0}`=session end
（`l1`）→ Harmony `onFocusChange`/编辑态 state+事件。

## 理由

`qle` case-2 emit `ll3`→`k0` 存活跃会话；`vle.l1()`
emit `ml3{k0}`+清空 —— 编辑会话边界事件对。

## 后果

Harmony 编辑会话 = state+focus 事件 —— 会话边界
语义保真。
