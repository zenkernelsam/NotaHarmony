# Phase 1212 证据 — u8e = Compose PointerInputScope（指针输入管线）

来源：`defpackage/{u8e,iqa,oqa,jqa,laj}.java`。

## `u8e` = PointerInputScope 实现

```java
import androidx.compose.ui.input.pointer.PointerInputEventHandler;
import androidx.compose.ui.input.pointer.PointerInputResetException;

final class u8e extends od8 implements bra,r93,ara {
    PointerInputEventHandler Y;    // 用户处理函数
    iqa a0 = q8e.a;                // 上一事件（EMPTY）
    ql8 b0,c0,d0;                  // 事件/续体槽
    Object g1(wx4, ef2) {          // = awaitPointerEvent 挂起
        ad1 cont = new ad1(1, ba6.J(ef2));
        t8e res = new t8e(this, cont);
        synchronized (c0) {
            b0.d(res);             // 入续体槽
            new dbc(ba6.J(ba6.B(res,res,wx4))).resumeWith(mof.a);
        }
        cont.v(new ki(res,19));    // 取消回调
        return cont.s();           // 挂起返回事件
    }
}
```

`g1` = `awaitPointerEvent` 挂起实现 —— `ad1` 可取消
续体 + `ql8` 槽 + `dbc` 投递恢复。

## `u8e.A(iqa,jqa,long)` 管线

```java
f0 = j;                            // 时间戳
if (jqa==jqa.I) a0 = iqa;          // 状态追踪
if (Z==null) Z = xj2.A(...,ko8,...); // 懒启动指针协程
h1(iqa, jqa);                      // 分发 PointerInputEventHandler
for (oqa p : iqa.a)
    if (!laj.e(p)) e0 = iqa;       // changed 追踪
```

- `iqa{List<oqa> a}` = **PointerInputEvent**（指针变更列表）。
- `oqa{d(),k(),e(),g(),j(),f()}` = **PointerInputChange**
  （id/位置/前位置/压力/消费/pressed 访问器）。
- `jqa` 3 值 = PointerEventType/Pass（`I`/`J`/`K`）。
- `laj.e(oqa)` = 变更判定；`M()` = 复位时重建
  清空 pressed 的合成事件（`I`/`J`/`K` 三连发）。

## Density / 复位

- `a()`/`e0()` = `ijg.m0(this).h0.a()` Density 透传。
- `K0()`/`e()`/`Z0()`/`M()` = 重置入口（节点脱离/输入
  复位→合成释放事件）。

## Harmony 决策

`PointerInputScope`/`awaitPointerEvent` → ArkUI
`onTouch`/`onAreaChange` + `MultiFingeredTouchHandler`
点列表；`oqa` PointerInputChange → `TouchEvent`
点结构；`jqa` 事件类型 → `TouchType` 映射。

## 产出

- fixture `d02-pointer-input.mjs`（10 断言）。
- ADR-1156；中文报告。
