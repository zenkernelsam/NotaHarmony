# Phase 1192 证据 — 编辑器 ViewModel（vle）+ undo apply（dve 逆 op）

来源：`defpackage/{vle,n73,od8,dve}.java`。

## `vle extends n73(→od8→j73)` = 笔记编辑器 ViewModel

```java
vle implements lo3,cma,mvc,o65,ara,jm6,q52,rd8,sn9,kv6,mp4:
  pdf Y, ype Z, joe a0, a46 b0, nn6 d0     // 编辑器依赖
  bq4 i0, u8e j0, ol3 l0, pg0 o0,
  tle p0, qle q0, ple s0, p6a t0         // *le 编辑器态
  A(iqa, jqa, long)                       // 触摸输入（iqa 归一
                                        //   事件，Phase 1175）
  H(KeyEvent)                             // 按键
```

`od8 implements j73` = ViewModel 基（`j73` = lifecycle）。

## undo apply 机制（vle 内联）

```java
nnf nnfVar = wx5.J;             // undo 态
ekd ekdVar = nnfVar.b;          // undo list
if (!ekdVar.isEmpty() || dve!=null) {
  if (ekdVar.isEmpty())
    z26.c("error: call undo while nothing to undo;
           check `canUndo` first")        // canUndo 守卫
  objC1 = au1.C1(ekdVar);        // pop undo
  nnfVar.c.add(objC1);           // push redo
  dve dveVar = (dve) objC1;      // **逆 op 记录**
  int i6 = dveVar.a;             // pos
  dleVar.c(i6, dveVar.c.length()+i6, dveVar.b);
                                 // 逆文本编辑 apply
  long j5 = dveVar.d;            // ts
}
```

`dve` = **逆 op 记录** `{a=int pos, b=text, c=len, d=ts}`
—— undo = pop undo→push redo→`dle.c(pos,pos+len,text)`
逆编辑 apply。

## 判定

编辑器 ViewModel = **Android ViewModel**（`n73/od8/j73`）：
归一输入 `iqa`→编辑 op→`nnf` undo 栈；`canUndo` 守卫
+ `dve` 逆 op apply —— op 级文本可逆。

## Harmony 决策

- `vle` → Harmony 编辑器组件 VM（`@Observed`/`MVVM`）。
- `dve` 逆 op → Harmony op 逆变换 + `dle.c` apply。
- `canUndo` 守卫 → Harmony `canUndo` 状态 + undo 前检。

## 产出

- fixture `d02-editor-vm.mjs`（10 断言）。
- ADR-1136；中文报告。
