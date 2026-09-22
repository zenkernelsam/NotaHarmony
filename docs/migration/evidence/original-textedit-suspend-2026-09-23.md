# 原版证据：文本编辑器挂起语义（pke / NoneActive）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 602 依据。

## 1. `rke` 事件三态

`uke.d(ukeVar, rkeVar, z, i)` 按 `rke` 分流：

| rke | 语义 |
|---|---|
| `qke(id)` | 激活指定块编辑器（`uke.p.get(id)` 命中已有 `ake` 会话则复用） |
| `oke.a` | 停用：`asdVar = ukeVar.b()`（`b()` 取 `p.get(null)` 兜底会话），销毁 |
| `pke.a`（"NoneActive"） | 挂起：`asdVar = null`——编辑器隐藏，`ake` 会话**保留在 `uke.p`** |

## 2. `pke` 仍提交内容（uke.d 尾部，z3=false 路径）

```java
mke mkeVar3 = akeVar.n;
qo5 qo5Var2 = akeVar.f;
// 守卫：块仍存在、无未决 op、文档可解析
xj2.A(ukeVar2.c, null, null,
    new mub(ukeVar2, xheVar, x09VarA, qo5Var2, null, 8), 3);
```

挂起时草稿照常写回文档（mub 协程），会话保留供再激活恢复
光标等状态。`mej.g(mke, TRUE, !z3, z3, …, 20)` 同时隐藏 IME。

## 3. 分发点

- `ct0.java:48` — ClearSelection 手势（选区面）→ `xtc.d(pke.a,false,true)`
- `uw2.java:114` — TapToSelect 手势 → `xtc.d(pke.a,false,true)`
- `uke.java:211` — 外部文本块变更命中活动块 → `d(uke,pke.a,false,6)`
- `g1f.java:257` / `pg3.java:91` — 其他 UI 面 → `uke.d(…,pke.a,false,6)`
- 对照：`zl2.java:203` TEXT 工具面块外点按 → `oke.a`（销毁）

## 4. Harmony 对齐

- `ToolType.DEFAULT`（= 原版 TEXT 工具面）块外点按 → `onTextCommit` 销毁。
- 其余工具（SELECTION/PEN/… 均挂 dl1 选区分发面）块外点按 →
  `suspendTextEditing()`：`onTextCommit` 提交内容 + 成功后
  `suspendedCaretByBlock.set(block.id, caret)`。
- `beginTextEditingAt` 命中块 → `textEditingRestoreCaret = map.get(id)` →
  `TextBlockOverlay` 以 `TextAreaController.caretPosition` 恢复光标。
- Done/Cancel（显式销毁）与页面切换清除挂起条目。
