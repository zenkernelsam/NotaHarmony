# 原版证据：无选区时点按元素直接选中（dl1 case2 末支 → vtc）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 599 依据。

## 1. `dl1` case2 分发链（xtc 选区手势按下）

`dl1` case2 是 `xtc`（选区交互控制器）的按下分发器，经
`xa5`→`rz1.C` 挂到多个工具表面。分支链末尾：

```java
} else if (ktcVar == null) {              // 无选区状态
    if (z3 && (ptcVarA = xtcVar.a(jE, null)) != null) {
        ttcVar = new vtc(ptcVarA);        // 命中元素 → TapToSelect
    } else {
        ttcVar = utcVar;                  // 未命中 → utc（落空）
    }
    ...
    if (ttcVar instanceof vtc) {
        return new uw2(xtcVar, z2, (vtc) ttcVar, i);
    }
    ...
}
return null;                              // utc → 不接管手势
```

## 2. `vtc` 续段（`uw2` case3）

```java
if (z) xtcVar.d(pke.a, false, true);
ptc ptcVar = vtcVar.a;
if (ptcVar instanceof ntc) {              // 命中 cqc 组
    cqc cqcVar = ((ntc) ptcVar).a;
    fvbVar2.a.d(new gtc(qo5Var, setX2, cmbVar2));   // 组选区状态
    k1aVar = new k1a(gtcVar, new fi3(cmbVar2));
} else {                                   // 单元素
    vnd vndVar = ((otc) ptcVar).a;
    k1aVar = new k1a(fvbVar2.d(vndVar.I.getId()), new fi3(...));  // itc
}
xtcVar.d.c(((fi3) k1aVar.J).a, (ktc) k1aVar.I);
```

按下即产生 `itc`/`gtc` 选区状态；同一手势后续移动由
`wtc`/`e39` 拖动机制处理（点住即可拖）。

## 3. `z3` 门（指针类型）

`z3 = !(z && !zH)`，`zH = elh.h(...)` = 手指触摸（允许时）或
侧键/右键。`rz1.C` 两个挂点：

- `nti:308`（PEN/PENCIL/HIGHLIGHTER/REVIEW/ERASER）：`z=false,
  z2=true` → `z3` 恒真 → 任意指针点选；`z2` 使同元素点按在
  `ufbVar.I != null`（活动编辑会话）时降为 `utc`。
- `nti:467`（TEXT，`eke` 编辑分支）：`z=true` → `z3=zH` →
  仅手指/侧键点选，裸笔尖落空交给文本工具。

POINTER（`c5f`→`a6f.Q`）表面另经 `j74`/`ha5` 挂 `xtc`——
点选+拖动是 POINTER 工具核心语义。

## 4. Harmony 侧

`SELECTION` 工具合并了原版 SELECT（套索，`k5f`/`rz1.A`/`frc`）
与 POINTER（点选拖动，`c5f`/`xtc`）。原实现空选区按下一律
`beginSelection` 进套索——点按元素只能套索不能点选。
本 Phase 在 `selectionVisible=false` 分支、链接命中检查之后
加 `topmostPageElementIdAt` 命中 → `selectElementIds` +
`resolveOriginalGroupSelection`（vtc/`uw2` case3 等价），并置
`selectionDrag` 同手势拖动；未命中 → 原套索路径。
