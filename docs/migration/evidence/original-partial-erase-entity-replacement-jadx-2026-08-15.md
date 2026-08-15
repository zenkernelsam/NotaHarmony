# 原版 Partial Eraser 实体替换：JADX 证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- APK SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 主反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- JADX：1.5.6
- 日期：2026-08-15

`jt1.invokeSuspend()` 与 `wc.invoke()` 在普通 JADX 输出中只有 method dump。为避免把寄存器名猜成业务语义，
对这两个类另做 fallback 线性反编译；原版目录本身没有修改。

```powershell
jadx.bat --single-class defpackage.jt1 --single-class-output $env:TEMP\nota-jt1-fallback-20260815.java `
  --decompilation-mode fallback --comments-level debug com.gingerlabs.notability.apk
jadx.bat --single-class defpackage.wc --single-class-output $env:TEMP\nota-wc-fallback-20260815.java `
  --decompilation-mode fallback --comments-level debug com.gingerlabs.notability.apk
```

- `nota-jt1-fallback-20260815.java` SHA-256：
  `22E7F02B2483D45FEB577541C79CD90A601BC17EBE8FACAFE94859B06856BEA5`
- `nota-wc-fallback-20260815.java` SHA-256：
  `17A0E86702415B5A4181F8F2B1E81E147AD23D3B6DA1DEDB3C60B58B97679895`

## `dh5`：普通落笔与 partial erase 是两条提交路径

普通单 Ink 落笔把结果交给 `new wc(..., 2)`，并立即检查是否产生 CREATE_INK：

```java
m1d.L(..., new wc(arrayList5, xgbVar3, mnbVar2, qo5Var9, 2), 8);
if (mnbVar.I == null) {
    o14.l("No CREATE_INK op found in dispatchEndActiveStroke");
}
```

工具状态为 `d04.J` 时不走上述普通 CREATE_INK 分支，而启动 `jt1`：

```java
if (q4fVar.b() == d04.J) {
    ...
    new jt1(kt1Var5, ..., listL0, qo5Var2, xgbVar4, andSet, null)
}
```

所以 tool 5 是 partial-erase 交互输入，不等于最终必须留在页面上的遮罩实体。

## `jt1`：裁剪后得到“删除源 + 每个源对应若干残片”

普通 Ink 分支先计算擦除轮廓，再把轮廓裁剪结果转换为新 Ink：

```java
java.util.ArrayList r5 = defpackage.n8j.e(r5, r6)
...
java.util.ArrayList r5 = defpackage.o8j.a(r11, r6, r5)
```

Shape/Pencil 还有各自的 `shapeErasePaths` 与 `pencilEraseSupport`，不能简单降级成中心线 Ink 裁剪。

对于完全删除与部分替换，源实体都会进入删除集合；部分替换还会把新 Ink 列表写入 remnant map：

```java
r3.add(r9)
...
r3.add(r9)
java.util.ArrayList r1 = r8.a
r7.put(r9, r1)
```

最后以 `vw6(..., deletions, remnants)` 形成计算结果，并通过 `new wc(..., 3)` 提交：

```java
r0.<init>(10, r3, r7)
...
wc r19 = new wc
r19.<init>(r20, r21, r22, r23, 3)
defpackage.m1d.L(..., r19, 8)
```

## `o8j.a()`：每个几何残片成为一个新 Ink，并重算录音区间

`o8j.a()` 对每个保留区间重新调用 `u5j.g(...)` 构造 `dm2`，再包装为 `jrb` 加入结果：

```java
jrbVar = new jrb(u5j.g(...), ...)
...
arrayList9.add(jrbVar)
```

若源 Ink 带录音时长，残片先把路径区间归一化为 `[startRatio, endRatio]`，然后计算：

```java
duration = clamp(round((endRatio - startRatio) * sourceDuration), 0, 0xFFFFFFFF)
audioStart = sourceAudioStart + clamp(round(startRatio * sourceDuration), 0, 0xFFFFFFFF)
```

这意味着多个残片不能都继承完整的 `audioStartTime/audioDuration`。

## `wc` mode 3：创建残片、维护 Group、删除源实体、结束 transient interaction

每个 `jrb` 残片先转换并提交为新 Ink：

```java
jrb r13 = (defpackage.jrb) r13
dm2 r14 = r13.a
...
qo5 r13 = r4.a(r13)
r12.add(r13)
```

之后原版把源 Group member 替换为新 Ink；若 Group 变空，还会继续向上处理空 Group。最终删除源实体：

```java
defpackage.au1.Y0(r9, new fg2(r7, 1), 1)
defpackage.au1.O0(r9, r7)
...
s83 r15 = defpackage.u5j.l(r1, r0, 0, 14)
```

最后 `oqi.a(...)` 结束 transient interaction。页面的持久结果因此是新 Ink 加源 Ink tombstone，而不是永久
`destination-out` tool-5 图层。

## 当前 Harmony 实现边界

- 已实现：普通非 Pencil、非 custom/fill outline Ink 的实体残片替换；保留 transform、源 z-index、Ink
  effects/path phase 与 AudioLinked 区间；CREATE remnants + DELETE sources；专用持久 Undo/Redo。
- 尚未宣称完成：Group member replacement/空 Group 删除、Shape partial erase、Pencil/custom outline 精确
  clipping，以及 transient preview/end 的完整协议对齐。
