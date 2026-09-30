# Phase 1246 证据 — wj8/w7d SharedFlow 事件总线

来源：`defpackage/{wj8,w7d,w41,v7d,s7d}.java`。

## `wj8` = t76 事件总线

```java
v7d a = w7d.b(0, 16, w41.J, 1);
// = MutableSharedFlow(replay=0, extraBufferCapacity=16,
//   onBufferOverflow=DROP_OLDEST)
Object a(t76, ef2) → a.emit(t76)     // suspend emit
boolean b(t76)   → a.tryEmit(t76)    // 非阻塞
```

## `w7d` = SharedFlow 工厂

```java
static f02 a = NO_VALUE sentinel;
static v7d a(i, i2, w41) {
    if (i2<0) "extraBufferCapacity cannot be negative";
    if (i==0 && i2==0 && w41==default) → replay/extra 须正
}
static ml4 d(s7d, yh2, i, w41)      // conflate/transform
```

## `w41` = BufferOverflow 枚举

`I`=SUSPEND, `J`=DROP_OLDEST, `K`=DROP_LATEST.

## 语义

- `wj8` = **`MutableSharedFlow`**（`replay=0`、`extra=16`、
  `DROP_OLDEST`）—— t76 事件总线：消费者滞后时丢
  最老事件（防卡顿溢出）;
- `wj8.b` = tryEmit 非阻塞（UI 线程安全发射）；
- `wj8.a` = emit 挂起（背压等待）；
- `w7d.d` = `conflate`/`shareIn` 变换；
- `f02` NO_VALUE = 空值哨兵（SharedFlow 内部）。

## Harmony 决策

`MutableSharedFlow` 事件总线 → Harmony `Emitter`/`Callback`
+自研有界队列（DropOldest 防溢出）—— 总线语义保真。

## 产出

- fixture `d02-event-bus.mjs`（10 断言）。
- ADR-1190；中文报告。
