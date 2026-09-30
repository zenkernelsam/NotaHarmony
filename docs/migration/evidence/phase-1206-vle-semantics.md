# Phase 1206 证据 — vle.h 语义/自动填充层 + j1 动作派发

来源：`defpackage/{vle,xvc,wvc,tvc,vvc,dli}.java`。

## `vle.h(xvc)` = Compose Semantics + Autofill 填充

`xvc` = `SemanticsPropertyReceiver`（`void g(wvc,Object)`）；
`wvc` = SemanticsProperty 键；`tvc` = Compose
`SemanticsProperties` 静态键注册表（ContentDescription/
StateDescription/ProgressBarRangeInfo/PaneTitle/
SelectableGroup/CollectionInfo/Heading/TextEntryKey/
Disabled/LiveRegion/Focused/IsTraversalGroup/
IsSensitiveData/…）；`vvc` = 扩展属性 + `AutofillValue`。

`vle.h` 填充：

| 键 | 值 | 语义 |
|---|---|---|
| `tvc.F`/`G` | `a00`（AnnotatedString） | 选区前/后文本 |
| `tvc.H` | `jqe(j)`（long-packed） | **textSelectionRange** |
| `tvc.I` | `jqe(M)` | **textCompositionRange** |
| `tvc.M` | `x36`（bool） | editable 标志 |
| `tvc.j` | `mof.a`（`!c0` 时） | Disabled |
| `tvc.Q` | `Boolean c0` | 状态 |
| `vvc.e` | `t3i.K` | contentDescription |
| `vvc.h` | `kr(AutofillValue.forText(ele))` | **AutofillValue** |
| `vvc.c` | `ole`（ix4 lambda） | 点击/动作 |

`wk8` 属性引用可见 Compose 命名（`editableText/
textSelectionRange/textCompositionRange/imeAction/
isEditable/maxTextLength/customActions/fillableData`）
—— 文本域完整语义面：TalkBack 朗读 + IME 组合区
+ 自动填充。

## `vle.j1(int)` = 动作派发

```java
if (i==6) hp4(ep4 aa6.v(this,v52.i)).h(1,true);   // 动作A
if (i==5) hp4(...).h(2,true);                     // 动作B
if (i==7) ((a83)o1()).a();                        // 键盘动作
```

`n1(i)` = `in6.a(new rle(this,i,0))` 延迟派发或回落 `j1`。

## `k1`/`l1`/`m1` 生命周期

- `k1()` = 取消 `tqd` job + `el8.a()` 释放（键盘协程清理）。
- `l1()` = 冲刷 `ll3` → `g0.b(new ml3(ll3))` 补发结束事件。
- `m1()` = `i0.d0.l1().b() && (u6g m0).c()` 能力门。

## Harmony 决策

- `xvc`/`tvc` 语义键 → ArkUI `accessibilityText`/
  `accessibilityDescription` + 文本选区语义。
- `AutofillValue.forText` → Harmony 自动填充框架
  （`autoFill`）。
- `j1` 动作码 5/6/7 → Harmony 自定义动作表。

## 产出

- fixture `d02-vle-semantics.mjs`（10 断言）。
- ADR-1150；中文报告。
