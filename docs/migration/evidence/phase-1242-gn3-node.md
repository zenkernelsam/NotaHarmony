# Phase 1242 证据 — gn3 编辑器 Node（mn3→nn3/ln3 双终态）

来源：`defpackage/gn3.java`。

## `gn3` = `n73`+`ara`+`pz5`+`q52`+`b25` 编辑器 Node

```java
abstract class gn3 extends n73 implements ara, pz5, q52, b25 {
    new mn3();                            // down start
    nn3 = new nn3(mn3Var);               // end-A
    ln3 = new ln3(mn3Var);               // end-B
    m1() → wj8.b(new ln3(mn3Var));        // detach/end-B
    A1/p1/x1/w1/y0/o1/r1/z1/m0/m1/v1/u1   // 指针生命周期
    a0(oqa)                              // 指针变更检查
    D(hz5)                               // 谓词
}
```

## 语义

- `gn3` = 又一抽象编辑器 `Modifier.Node`（`n73`）——
  `vle`/`k2`/`bk5`/`gn3` 家族第 4 位；
- `mn3` start + **`nn3`/`ln3` 双终态**（`m1`→`ln3`）——
  对应手势正常结束 vs detach/取消终态；
- 指针生命周期全（`A1`/`p1`/`x1`/`w1`/`y0`/`o1`/`m1`…）；
- `pz5`/`q52`/`b25` = 手势/选择/输入子集 iface。

## Harmony 决策

`gn3` Modifier.Node → Harmony 组件/State 节点 +
onTouch → `mn3`/`nn3`/`ln3` 事件 —— 双终态语义保真。

## 产出

- fixture `d02-gn3-node.mjs`（10 断言）。
- ADR-1186；中文报告。
