# Phase 1248 证据 — u8e pointerInput Modifier.Node

来源：`defpackage/{u8e,bra,ara,q8e,ql8}.java`。

## `u8e` = pointerInput 节点

```java
u8e extends od8 implements bra, r93, ara {
    Object W,X;                        // coroutine ctx
    PointerInputEventHandler Y;        // 用户 handler
    tqd Z;                             // handler job
    iqa a0 = q8e.a;                    // 当前事件
    ql8 b0,c0,d0;                      // 3 事件历史列表
    iqa e0; long f0;                   // prev + downTime
}
```

`bra`=PointerInputScope iface（extends `r93` Density）；
`ara`=j73 input-dispatch iface。

## 语义

- `u8e` = Compose `pointerInput` Modifier 节点 ——
  `od8` Node 内跑 `PointerInputEventHandler` 协程；
- `iqa a0` = 当前 `PointerInputEvent`；
- `ql8`×3 = 事件历史队列（Pressed/Moved/idle）；
- `f0` = downTime（按下时刻，长按计时）；
- `g1` = awaitPointerEvent suspend（协程式事件读）；
- `PointerInputResetException` = 节点重组时取消 handler。

## Harmony 决策

pointerInput+awaitPointerEvent → Harmony `onTouch`+
组件 state+协程 —— 指针 scope 语义保真。

## 产出

- fixture `d02-pointer-scope.mjs`（10 断言）。
- ADR-1192；中文报告。
