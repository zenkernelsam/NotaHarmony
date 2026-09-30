# Phase 1247 证据 — iqa/oqa/jqa 指针输入数据

来源：`defpackage/{iqa,oqa,jqa,hc0}.java`。

## `iqa` = PointerInputEvent

```java
List a;           // List<oqa> 多指针变更
hc0 b;            // MotionEvent 源
int c,d,e,f;      // 分类（getActionMasked 派生）
iqa(List, hc0) {  // 按 actionMasked 算 c/d/e
}
MotionEvent a();  // 原生事件
```

## `oqa` = PointerInputChange（11+ 字段）

```java
long a,b,c;       // id, uptimeMillis, position
boolean d;        // pressed
float e;          // pressure
long f,g;         // previousUptime, previousPosition
boolean h;        // previousPressed
int i;            // type (Touch/Stylus/Mouse/Eraser)
long j;           // scrollDelta / consumed
float k;          // ...
```

## `jqa` = PointerEventType 枚举 {I,J,K}

`jqa I/J/K` = Initial/Press/Move 三类指针事件类型。

## 语义

- `iqa` = Compose `PointerInputEvent`（多指针变更列表 +
  `hc0` MotionEvent 源 + 按 actionMasked 的分类）;
- `oqa` = Compose `PointerInputChange` —— 指针变更全记录
  （id/uptime/pos/pressed/pressure/previous*/type/consumed/
  scrollDelta）;
- `jqa` = Compose `PointerEventType`（Initial/Press/Move）；
- `iqa.a()→MotionEvent` = 解包原生事件。

## Harmony 决策

PointerInputEvent/Change → Harmony `TouchEvent`/
`TouchObject`（id/pos/pressed/type/history）—— 指针
数据语义保真。

## 产出

- fixture `d02-pointer-data.mjs`（10 断言）。
- ADR-1191；中文报告。
