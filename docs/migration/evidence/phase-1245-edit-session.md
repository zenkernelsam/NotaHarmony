# Phase 1245 证据 — ll3/ml3 编辑会话边界事件

来源：`defpackage/{qle,vle}.java`。

## `ll3` start（qle case 2 → vle.k0）

```java
case 2:
    ll3 = new ll3();
    vle.g0.b(ll3);          // wj8 通道 emit
    vle.k0 = ll3;           // 存为当前会话
    yni.c(vle);
```

## `ml3` end（vle.l1()）

```java
void l1() {
    if (k0 != null) {
        g0.b(new ml3(k0));   // 包 start → end emit
        k0 = null;
    }
}
```

## 语义

- `ll3` = **编辑会话开始**（tap/focus 进入编辑时 `qle`
  case-2 创建 → `g0`=wj8 通道 → `k0` 存当前）;
- `ml3{ll3}` = **编辑会话结束**（`vle.l1()` = session-end
  —— detach/提交边界）;
- `k0` = 活跃会话句柄（`null` 检查防 double-end）；
- `g0` = `wj8` 事件通道（`wj8.b(0,16,DropOldest)`）；
- `m1()` = `i0.d0.l1().b() && g37.c()` —— 会话中判断。

## Harmony 决策

`ll3`/`ml3` 会话事件 → Harmony `onFocusChange`/
编辑态 state + 事件 —— 会话边界语义保真。

## 产出

- fixture `d02-edit-session.mjs`（10 断言）。
- ADR-1189；中文报告。
