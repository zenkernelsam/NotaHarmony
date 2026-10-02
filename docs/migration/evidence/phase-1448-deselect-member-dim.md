# Phase 1448 证据：1.4.2 `hak`/`oo7` deselectMode 点除成员灰显

## 原版证据（`decompiled_1.4.2/sources/defpackage`）

### 点除集注入渲染协程（`kgi.java:101-116`）

```java
isf isfVar = msfVar instanceof isf ? (isf) msfVar : null;
if (isfVar != null) {
    if (!isfVar.h) { isfVar = null; }
    if (isfVar != null) { set4 = isfVar.i; }   // deselectMode 时取点除集
}
Set set6 = set4 == null ? rm4Var : set4;
tee.a0(n54.a, new hak(r0bVar, z2, false, set5, exjVar, set2, list, z,
    set, set6 /* → hak.o0 */, iakVar, ...), jgiVar);
```

`isf.h` = deselectMode；`isf.i` = 累计点除成员集（mud case7 `i′=i∪set6`）。
仅 deselectMode 下点除集注入 `hak`；否则 ∅。

### 渲染集装配（`hak.java:482/572/629/666`）

```java
Set set42 = hakVar3.o0;                 // = 点除集
...
set = set42;                            // 分支内局部 set = 点除集
LinkedHashSet linkedHashSetF0 = y2g.f0(hakVar3.n0, set);   // n0 ∪ 点除集
...
oo7.c(oo7Var, linkedHashSet9, linkedHashSetF0, set6, ...); // set2 = F0
```

`y2g.f0`（y2g.java:55-67）为**并集**（`addAll(set)` + `addAll(iterable)`）。
`n0` = `kgi.h` 第 4 参（页渲染管线的既有灰显/裁剪候选集；协程体 jadx
反编译失败，精确语义未解——但不影响点除集 ⊂ 灰显集的结论）。

### 笔画灰显（`ho7.java:93/179` → `x1h.i` → `oo7.java:201`）

```java
// ho7.h() 构造 x1h 笔画描述符：
new x1h(..., set.contains(mn7Var.getId()), ...);   // → 字段 i
// x1h.java:138：o() 返回 i
// oo7.java:201 绘制时：
float f6 = ((x1h) y1hVar).o() ? 0.2f : 1.0f;
```

命中集成员 → 描边/填充透明度乘子 **0.2**。`u1h`（非铅笔笔画）同构
（ho7:179 同款 `set.contains(getId())` 标志位）。

### Paint 级乘子（`oo7.java:632-638`）

```java
public static void x(Paint paint, int i, BlendMode blendMode, boolean z, Float f) {
    paint.setColor(i);
    paint.setBlendMode(blendMode);
    if (z) paint.setAlpha(o6k.s((int) (paint.getAlpha() * 0.2f), 0, 255));
    ...
}
```

`z` = 灰显标志 → **paint alpha 直接乘 0.2**（乘法语义，与元素自身透明度
复合）。

### 形状同构（`jo7.java:110/128/164/179`）

`f5g` 形状渲染：`zContains`/`zContains2`/`zContains3` = `set*.contains(
f5gVar.getId())` → `v1h` 描述符/`oo7.b` 的灰显标志。图片 `l97` 分支
（hak.java:1073 `set59.contains(((l97) obj6).getId())`）同样过滤集
成员。

### 语义归纳

- deselectMode 下，**点除成员在元素层渲染为 20% 透明度**（笔画/形状/
  图片同构；n0 并集项为另一灰显类别，不影响结论）。
- 选中保留成员满透明度；点除成员 0.2 → "淡出待删"视觉。
- 确认后 `isf.i` 清空（m5b case13 `dqd(17)` i=∅）→ 灰显解除。

## Harmony 对齐

| 原版 | Harmony |
|---|---|
| `isf.i` 点除集入渲染协程 | `SelectionTool.deselectedIds` → `renderOrderedElements` 消费 |
| `paint.alpha *= 0.2` | `AlphaScaledDrawingContext.setGlobalAlpha(a*0.2)` 委托缩放——渲染器内部绝对覆写（如笔画 s.opacity）同样被乘上等效 paint 乘法 |
| 五类元素叶子 id 灰显 | `element.elementId ∈ deselectedIds` → 换用缩放上下文（stroke/text/shape/image/math 全分支） |
| `isf.i` 清空解除灰显 | `deselectedIds=[]` 于 confirm/cancel/deselect/reset 全出口（既有实现） |
| 点除后立即重绘 | `deselectElements` 后 `renderFrame()`（既有分发链 3813-3819/3925） |
