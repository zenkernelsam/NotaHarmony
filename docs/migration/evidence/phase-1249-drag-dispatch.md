# Phase 1249 证据 — ol3/pl3/kl3/ame 拖拽分发

来源：`defpackage/{ol3,pl3,kl3,ame}.java`。

## `ol3` = 拖拽分发 Modifier.Node

```java
ol3 extends od8 implements vff, pl3, kv6 {
    ix4 W;                          // handler 注册
    ol3 X;                          // 嵌套分发
    pl3 Y;                          // 目标 handler
    long Z;
    void F(kl3);                    // dragStarted 分发
    boolean P0(kl3) {               // drop 消费
        return ol3Var.P0(kl3) || pl3Var.P0(kl3);  // 树遍历
    }
    void k0(kl3); void b(long); Object s();
}
```

## `pl3` = DragEvent handler iface

`P0(kl3)→bool`（消费）+ `w0`/`F`/`k0`/`b`/`s` default —
DragEvent 生命周期回调。

## `kl3` = `DragEvent` 包装器 `{DragEvent a}`

## `ame` = 5-callback `pl3` 实现

```java
ame(qle I, zy7 J, qle K,L,M,N) {          // 5 回调
    P0(kl3): clipData = dragEvent.getClipData();  // DROP 读剪贴板
    F(kl3)  → lambda
}
```

## 语义

- `ol3` = **拖拽分发树节点**：`P0`/`F`/`k0` 沿 Modifier
  树走（`ol3 X` 嵌套 / `pl3 Y` 目标）—— drag enter/
  over/drop 分层分发；
- `pl3` = DragEvent 回调 iface（`P0`=onDrop consume、
  `F`=dragStarted、`w0`=dragLocation、`k0`/`b`/`s`）;
- `kl3` = DragEvent 包装；
- `ame` = 5-λ `pl3` —— `P0` 读 `ClipData`（粘贴式 drop）
  + dragStarted/Entered/Exited/Location 回调。

## Harmony 决策

ol3/pl3/kl3 → Harmony `onDrop`/`onDragEnter`/`onDragLeave`
/`onDragMove`+`getData` —— 拖拽语义保真。

## 产出

- fixture `d02-drag-dispatch.mjs`（10 断言）。
- ADR-1193；中文报告。
