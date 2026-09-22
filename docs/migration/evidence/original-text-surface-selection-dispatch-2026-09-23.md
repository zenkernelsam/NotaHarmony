# 原版证据：TEXT 面选区手势分发 + 裸笔压制（dl1 z / elh.h）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 603 依据。

## 1. 表面挂载（nti.java）

```java
// line 308（手写面 z4f/b5f/t4f/g5f/r4f = PEN/PENCIL/…/ERASER）：
rz1.C(..., xtcVar2, false, true,  ...)    // z=false, z2=true
// line 467（TEXT 面 m5f = a6f.L = TEXT）：
rz1.C(..., xtcVar2, true,  false, ...)    // z=true,  z2=false
// SELECT(k5f)/POINTER(c5f) 另走 rz1.A/q8e 链。
```

`dl1` case2 是共享选区手势分发器，TEXT 面同样挂接。

## 2. z3 压制门（dl1.java:85-88 + elh.java:249）

```java
boolean z3 = true;
boolean zH = elh.h((Function0) obj4, iqaVar, oqaVar);
if (z && !zH) { z3 = false; }
// elh.h = (function0.invoke() && oqaVar.i == 1) || (iqaVar.d & 66) != 0
//       = 手指触摸 或 手写笔桶键（button 66 = SECONDARY|STYLUS_PRIMARY）
```

z3=false ⟺ TEXT 面 + 裸笔（非手指、无桶键）。压制只作用于
`rtc`/`vtc` 产出——覆盖层内 `wtc`/`ttc`/柄、`stc`/`qtc`、
`etc` 取消均不经门。

## 3. 各态外按门控（dl1 case2）

| ktc 态 | 覆盖层内 | 覆盖层外 |
|---|---|---|
| ftc 常态 | wtc/ttc（z3 不门） | z3 → rtc/vtc；!z3 → utc |
| ftc deselectMode | stc / utc / qtc | 同左（不门） |
| gtc | wtc（`z2‖ufb.I==null` 成员 ttc） | z3 → utc；!z3 → rtc/vtc ⚠ |
| itc | 同元素 ttc（`!z2‖ufb.I==null`） | (rtc‖vtc) && !z3 → utc |
| etc | —（任何按下 → rtc 取消绘制） | — |
| null | — | z3 且命中 → vtc；否则 utc |

⚠ gtc 外按臂与 ftc 字面相反：z3→utc、!z3→rtc/vtc。按字面
执行则纯组选区在手写/SELECT 面永远无法外按清除（z=false→z3
恒真）——判定为 JADX 臂交换反编译伪影，Harmony 采用 ftc 同
语义（z3→rtc/vtc），见 ADR-0572。

## 4. Harmony 对齐

`ToolType.DEFAULT`（= 原版 TEXT 面）pointer-down 在 tape/checkbox
后插入 dl1 分发：deselectMode（不门）→ 覆盖层内（柄/ttc/wtc，不门）
→ 外按 `!stylusSuppress` 才产 rtc/vtc（SourceTool.Pen≈裸笔，无桶键
信息 fail-closed）→ 落空交还文本手势面。
