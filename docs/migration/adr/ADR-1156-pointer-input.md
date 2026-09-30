# ADR-1156：u8e PointerInputScope 指针管线

## 状态

已接受（Phase 1212）。

## 决策

`u8e` Compose `PointerInputScope`（`awaitPointerEvent`
挂起 + `PointerInputEventHandler` + `iqa`/`oqa` 事件）
→ ArkUI `onTouch`/`MultiFingeredTouchHandler` 点列表；
`jqa` 事件类型 → `TouchType`。

## 理由

`u8e{PointerInputEventHandler Y, ql8 槽, g1 挂起循环}`
+ `iqa{List<oqa>}` 事件 + `oqa` 变更访问器 +
`laj.e` 变更判定 + `jqa` 3 值类型 —— Compose
指针输入完整实现。

## 后果

Harmony 指针输入 = TouchEvent 点列表 + 变更追踪 +
合成复位事件 —— 与 Compose PointerInput 语义对齐。
