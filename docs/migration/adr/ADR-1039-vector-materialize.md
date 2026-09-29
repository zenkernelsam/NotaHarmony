# ADR-1039：FB 向量→List 物化助手

## 状态

已接受（Phase 1095）。

## 决策

Harmony FB 向量物化 = `lv2.S` 模式：`count()` +
`k(elem,i)` per-index 绑定复用表 + `m18.S/E` 持久化；
空→`hw3.I`。

## 依据

`lv2.S(je8)`/`I(s83)`/`T(r29)` 同构实现。

## 后果

Harmony 向量读 = count+bind+持久化冻结；空共享 `hw3.I`。
