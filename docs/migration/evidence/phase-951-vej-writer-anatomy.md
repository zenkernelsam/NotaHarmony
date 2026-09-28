# Phase 951 证据 — `vej.q` 典型 op 写器解剖

## `vej.q(qub, builder)` 全文（实证）

```java
int iJ = qubVar.j();                    // locations 长度
ix4 wj9Var = iJ <= 0 ? sg5.o            // 空→哨兵
  : new wj9(9, sg5.b(), qubVar);        // 元素提供器
if (iJ < 0) {
  fa2.w(len, yn7.MODEL, "Got negative length");
} else {
  aVar.D(12, iJ, 4);                    // 12B 结构向量对齐 4
  for (i = len-1; -1 < i; i--)
    sg5.f(aVar, (exc) wj9Var.invoke(i)); // 逐 cxc 经 scratch 写
  numValueOf = aVar.o();
}
aVar.C(2);                              // 2 槽表
h(0, vecOff);                           // f0 locations
j(1, rh8.O(qo5));                       // f1 textField
n(); z(iN, 4);                          // f0 required
```

## 写端机制登记

| 部件 | 语义 |
|---|---|
| `wj9(stride, scratch, table)` | 向量元素提供器 lambda |
| `sg5.f(builder, exc)` | 单结构写入助手（草稿复用） |
| `sg5.b()` | cxc 12B scratch 实例 |
| `sg5.o` | 空迭代器哨兵（d1） |
| `D(bytes, len, align)` | 结构向量开始 |
| `rh8.O` | qo5 8B 内联写器 |
| `fa2.w(...,yn7.MODEL,"Got negative length")` | 负长日志 |
| `z(iN,4)` | f0 required |

## `vej` 混合内容

`a(AbstractList,qo5)`=qub 工厂；`b..r`=
hqe/ti3/di3 域助手（非线型）。

## 结论

op 写器统一解剖：元素提供器 + sg5 草稿 +
向量 D/b/o + 槽写 + required 标记。
