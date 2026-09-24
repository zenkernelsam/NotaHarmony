# Phase 694 — 原版字号步进（kre/pte → cve.l(f) → zyd.f clamp [4,72]）Evidence

## 范围

把原版字体格式簇中的字号步进控件（`kre`
FontSizeTextToolbarItem：当前字号显示 + ±1pt 增减钮）移植到
Harmony 文本块编辑覆盖层。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/kre.java`

```java
// FontSizeTextToolbarItem(size=..., onClick=..., onIncreaseSizeClick=...,
//   onDecreaseSizeClick=...)
public final float a;           // 当前字号
public final Function0 b;       // onClick（打开 qse.M 字号面板）
public final Function0 c;       // onIncreaseSizeClick
public final Function0 d;       // onDecreaseSizeClick
```

### 2. `sources/defpackage/ave.java`（L56-90）—— 步进语义

```java
kre kreVar = new kre(f, new oue(cveVar, 25),
    /* increase */ () -> cveVar2.l(f2 + 1.0f),
    /* decrease */ () -> cveVar2.l(f2 - 1.0f));
```

步进量 = **±1.0pt**，以当前字号 `f` 为基。

### 3. `sources/defpackage/cve.java`

```java
if (nueVar instanceof pte) {
    l(((pte) nueVar).a);
    i(qse.M);
    return;
}
...
public final void l(float f) {
    n(new zyd(null, null, null, null, null,
        Float.valueOf(rh8.u(f, 4.0f, 72.0f)),   // zyd.f = clamp[4,72]
        null, null, null, null, null, 2015));
}
```

`i31` case 20：`ix4Var.invoke(new pte(((Float) obj).floatValue()))`。

### 4. `sources/defpackage/ure.java`

`fontSizeState=`（r）为 `kre` 实例；与 `fontFormatState`（q）、
`fontFamilyState`（s）同属字体格式簇。

## Harmony 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `kre.a` 当前字号显示 | `Text(caretCharFontSize)` |
| `onIncreaseSizeClick` → `l(f+1)` | `Button('+')` → `stepFontSize(1)` |
| `onDecreaseSizeClick` → `l(f-1)` | `Button('-')` → `stepFontSize(-1)` |
| `rh8.u(f,4,72)` clamp | `Math.max(4, Math.min(72, current+delta))` |
| `zyd.f` 选区/pending 写入 | 选区 → `applyFontSize(next,s,e)` + normalize；折叠 → `pendingCharStyles.fontSize = next` |
| `kre.a` 字号来源（br2/zq2 态） | `fontSizeAt(s,e)`（选区首个携 fontSize run → element.fontSize 回落）；折叠 → `pendingCharStyles.fontSize ?? fontSizeNearCaret() ?? element.fontSize` |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`

## 验证

- `docs/migration/replays/d02-original-font-size-stepper.mjs`：
  16 项静态钉全绿。
