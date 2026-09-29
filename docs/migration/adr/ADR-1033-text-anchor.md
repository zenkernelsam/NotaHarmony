# ADR-1033：文本锚点三元序（C 反向）

## 状态

已接受（Phase 1089）。

## 决策

Harmony 文本序列位置 = `exc{a1:key, m:site, C:seq}`，
`(a1 → site → -C)` 全序——C 反向使同 site/同键时新插入
靠前。`kci.b` 构 INSERT_STRING（slot0=exc 位，
slot2=qo5 文本域）。

## 依据

`exc.A0` 三元比较 + `kci.b` op 构建。

## 后果

Harmony 文本 CRDT 锚点序含 C 反向——并发插入偏序正确。
