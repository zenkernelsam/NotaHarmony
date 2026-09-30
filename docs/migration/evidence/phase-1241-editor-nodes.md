# Phase 1241 证据 — k2/bk5/j2 编辑器 Modifier.Node 家族

来源：`defpackage/{k2,j2,bk5}.java`。

## `k2` = 编辑器 Modifier.Node 抽象基

```java
abstract class k2 extends n73 implements
    ara, jm6, mvc, vff, q52, sn9, pz5, b25 {   // 8 iface（vle 同族）
    bq4 f0;                                   // focus relay
    ck8 l0; t3i r0;
    f0 = new bq4(wj8, 0, "onFocusChange" methodref);
    H(KeyEvent);                               // 键处理
    fwa → new fwa(m0);                         // 长按 start
    wj8.b(new sj5(rj5Var));                    // emit sj5
    N0/V0/Y0/Z0/h(xvc)                         // Modifier 生命周期+semantics
}
```

## `j2` = `k2` coroutine 事件发

```java
j2 extends n8e implements wx4 {
    invokeSuspend: rj5 = new rj5(); ...; sj5 = new sj5(rj5);
}
```

## `bk5` = `od8`+`ara` 触控事件 Node

```java
bk5 extends od8 implements ara {
    A(iqa,jqa,long) {
        rj5 = new rj5(); ...; wj8.b(...)      // down
    }
    i1() → W.b(new sj5(rj5Var))               // detach → end
}
```

## 语义

- `k2`/`vle` 同族 —— **编辑器 Modifier.Node 多态**：
  `vle`=ink/主编辑，`k2`=抽象基（另一编辑类型）；
- `bk5` = 触控事件 Node —— `ara.A` 输入 → `rj5`/`sj5`
  发流（`i1` detach 清尾）;
- `fwa` = `k2` 长按手势（`m0` 时间戳）。

## Harmony 决策

`n73`/`od8` Modifier.Node 家族 → Harmony 组件/State
节点 + onTouch → 事件流 —— 编辑节点语义保真。

## 产出

- fixture `d02-editor-nodes.mjs`（10 断言）。
- ADR-1185；中文报告。
