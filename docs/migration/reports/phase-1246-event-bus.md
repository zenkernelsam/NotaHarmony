# Phase 1246 报告 — SharedFlow 事件总线

## 完成内容

- `wj8`=t76 事件总线：`MutableSharedFlow(replay=0,
  extra=16, DropOldest)`（滞后丢最老防溢出）+`a`=emit
  挂起/`b`=tryEmit 非阻塞；`w7d`=工厂（NO_VALUE+
  容量守卫+`d` 变换）；`w41`=BufferOverflow 枚举。

## 产出

- evidence `phase-1246-event-bus.md`
- fixture `d02-event-bus.mjs`（10/10）
- ADR-1190
