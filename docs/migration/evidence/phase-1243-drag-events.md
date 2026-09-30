# Phase 1243 证据 — bq1/bq4 zo4/ap4 拖拽事件

来源：`defpackage/{bq1,bq4,ns,rd9,mp5,yp5,zp5,ss8}.java`。

## `bq1` = 拖拽 summon 合成 lambda

```java
bq1 extends ty4 implements wx4 {
    zo4 = new zo4();                          // drag start
    r11.j1(wj8, new ap4(zo4Var));             // drag end emit
    xj2.A(rd9.h(), → ns(rd9, yp5/zp5, list, "Drag & Drop"))
}
```

`ns(rd9, yp5/zp5(clip?), list, "Drag & Drop")` = 拖拽
协程 —— `zo4`/`ap4` = **drag-and-drop 起/止事件**。

## `bq4` = focus-relay + ap4 emit

```java
bq4 extends n73 implements mvc,o65,q52,sn9,vff {
    xp4(i, "onFocusStateChange" methodref, 10);
    h(xvc).g(ivc.w, requestFocus semantics action);
    j1 → r11.j1(wj8, new ap4(zo4Var));        // focus/drag end relay
}
```

## 语义

- `zo4`/`ap4` = **拖拽 start/end**（非 focus —— `bq1`
  发起 drag，`bq4` relay 其 end via `j1`+`ap4(zo4)`）；
- `mp5`/`yp5`/`zp5`/`ss8` = ClipData/drag-shadow/拖拽
  载荷；
- `bq4` 兼任 focus（`onFocusStateChange`+`requestFocus`）。

## Harmony 决策

`bq1` drag summon+`bq4` focus relay → Harmony `onDrop`/
`onDragStart`+focus 事件 —— 拖拽语义保真。

## 产出

- fixture `d02-drag-events.mjs`（10 断言）。
- ADR-1187；中文报告。
