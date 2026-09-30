# Phase 1216 证据 — qoe = TextFieldState + wx5 undo 会话

来源：`defpackage/{qoe,wx5,spd}.java`。

## `qoe` = TextFieldState 编辑会话

```java
qoe {
    wx5 a;              // 委托/undo 会话
    dle b;              // TextEditBuffer（编辑构建器）
    p6a c,d,e;          // MutableState（文本/选区/组合）
    spd f;              // 处理器（tpd,p7e,e8）
    ql8 g;              // 待决操作列表
}
```

## `qoe.a(qoe,a46,z,bme)` = 中央应用路径

```java
eleVarD = d();                    // 当前文本
if (无变更 && 选区同) return;      // no-op 快速路径
eleVar = new ele(string,j2,jqe,P,tgi.a(jqe,O));
i(eleVarD, eleVar, z2);           // 内部更新
e(eleVarD, eleVar, b.a(), bme);   // 应用编辑（含 bme 模式）
dleVar3 = new dle(eleVar, b.a(), eleVarD, null, 8);
a46.i(dleVar3);                   // → CRDT 编辑 sink!
svd.d0(dleVar3.K, eleVar);        // 校验
```

`f(true)` = 每次提交标 undo 边界。

## `wx5` = undo 会话（nnf 宿主！）

```java
// wx5.J = nnf
nnf nnfVar = (nnf) this.J;
ekd undo = nnfVar.b; ekd redo = nnfVar.c;
redo.clear();
while (undo.size()+redo.size() > nnfVar.a-1)
    undo.remove(0);               // 容量淘汰最旧
undo.add(dveVar);                 // 推 dve 逆操作
```

`wx5 implements szd,bs7,nn1,rwa,n7b` — 编辑动作
委托（IME 会话 + 逆操作记录）。

## 链条确认

`vle` → `pdf`(TransformedTextFieldState) → `qoe`
(TextFieldState + `dle` buffer + `a46` sink) → `wx5`
(undo 会话) → `nnf`(有界 undo/redo) → `dve`(逆操作)
—— 完整撤销链打通（Phase 1190/1191/1215 收敛）。

## Harmony 决策

`TextFieldState`+`TextEditBuffer`+undo 会话 →
Harmony `TextEditState` + 逆操作 undo 栈（容量
淘汰+redo 清空语义对齐）。

## 产出

- fixture `d02-qoe-textfield-state.mjs`（10 断言）。
- ADR-1160；中文报告。
