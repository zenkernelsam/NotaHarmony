# ADR-1190：wj8 SharedFlow 事件总线

## 状态

已接受（Phase 1246）。

## 决策

`wj8` MutableSharedFlow(0,16,DropOldest)+emit/tryEmit
→ Harmony `Emitter`/Callback+自研有界队列。

## 理由

`wj8`=t76 总线：`replay=0`+`extra=16`+`DROP_OLDEST`
（滞后丢最老防溢出）；`w41`=BufferOverflow —— 事件
总线机制。

## 后果

Harmony 事件总线 = Emitter+有界队列 —— 总线语义
保真。
