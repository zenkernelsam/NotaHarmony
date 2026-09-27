# Phase 933 证据 — `lv2` 全量线型物化器登记表

## 目的

`lv2` 静态类中线型相关方法的完整登记
（Compose 助手除外）。

## 通用模式（实证）

```
len = table.c(N)/len()        // 向量长
if len==0 → hw3.I             // 空表哨兵
buf = m18.S()                 // 可变 th7 构建器
per-index: elem = new T(); table.j(elem,i) 或 bytes
return m18.E(buf)             // 冻结不可变 List
```

`th7` 返回 = u4 RandomAccess 可变表（热路径）；
`List` 返回 = 冻结表。

## 物化器登记（实证）

| 方法 | 入参表 | 元素 | 输出 |
|---|---|---|---|
| A(dm2) | CreateInk | 原始字节 | ei7 迭代器 |
| B/E(dm2) C/F(wd8) | ink ops | 字节表 | nl8 |
| D/G(dm2) | CreateInk | 打包路径 | di7 |
| f0(dm2) g0(wd8) M(wd8) | ink ops | qo5 引用 | th7/List |
| H(my3) | EntityAnchor | qo5 | List |
| I/J/W/X(s83) | DeleteEntities | qo5+cxc ×4 向量 | th7 |
| N(qub) O(f2c) | char ops | cxc 位置 | List |
| P(cm2) Q(vd8) | group ops | qo5 成员 | List |
| S(je8) | ModifyPositions | ie8 子表 | List |
| T(r29) | NoteBundle | uq9 ops | List |
| U(vt9) | OpsBundle | uq9 ops | List |
| V(zgb) | ReceiveOpsEvent | uq9 ops | List |
| Y(ge8) | ModifyPage | cxc 页 | List |
| a0(pra) | Polygon | fqa 点 | List |
| b0(yn2) c0(ke8) | recording ops | ukb 段 | th7 |
| d0(yda) | PeerInteraction | qo5 选中集 | th7 |
| e0(le8) | ModifyShape | qo5 形状 | List |

## 非线型成员（登记备查）

`oz/pz/qz/rz` ±INFINITY 浮点哨兵；`zp9(7)`；
`wz6[0]`；`o5d.M`；`l=8f m=24f`；`b/c/d/e/f/g/h`
Compose 大函数；`Z(Bundle)` 平台辅助；
`K/L(m15,o15)`、`h0`、`B0`、`C0`、`D0`、`A0`
杂项。

## 结论

全量物化器登记：26 线型物化器统一
S→逐元素→E→hw3.I 模式。
