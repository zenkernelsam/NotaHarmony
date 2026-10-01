# Phase 1446 证据：1.4.2 `zf3` 覆盖层内按下分发（lsf 支补全）

## 原版证据（`decompiled_1.4.2/sources/defpackage`）

### `zf3.java` case1 —— 选区工具点按分发器

输入：当前选区 `msfVar`（`ome.h`）、点按位 `jE`、面旗标 `z2`/`z`。
选区一致性守卫：`dtfVar.b.f.F` 与 `ome.h` 的 `getId()` 不等 → `null`（stale 忽略）。

`ksf` 支（`isf`/`jsf`，`h=false` 常态）：

```java
if (f5n.h(ksfVar.a(), jE, ksfVar.g(), u64.b(...))) {   // 界内
    if (!(ksfVar instanceof jsf)) {
        btfVar = new ctf(ksfVar.d(), ksfVar);           // isf 一律拖拽
    } else if (z2 || r3eVar.F.getValue() == null) {
        epgVarE = dtfVar.d.e(jE, omeVar.b(), null);     // 命中测试
        if ((ro4VarC instanceof vvh) || !jsf.b.contains(epgVarE.G)) {
            btfVar = new ctf(((jsf) ksfVar).d, ksfVar); // 拖整组
        } else {
            btfVar = new zsf(epgVarE.G, jE);            // 非 vvh 组成员 → zsf
        }
    } else { btfVar = atfVar; }                          // 编辑会话激活 → None
} else if (z3) { 命中 → btf : xsf } else { atf }         // 界外
```

`lsf` 支（点选型单元素，**无界内判定，直接命中分发**）：

```java
tsfVarA4 = dtfVar.a(jE, null);          // 页级命中测试
null            → xsf                    // rv0 清选
rsf（组）        → btf                   // 重选组
ssf 异元素      → btf                   // 重选 lsf
ssf 同元素      → vvh ? zsf : ctf        // 文本进编辑；非文本拖拽
                //（z2 且编辑会话激活 → atf None）
尾部：(xsf|btf) && !z3 → atf            // 裸笔压制落空/重选
```

`hsf`（进行中套索）→ 恒 `xsf`。`msfVar==null` → 命中 → `btf`，落空 → `atf`。

### 终局映射（`zf3` ~268-281）

| 中间事件 | 分发 | 语义 |
|---|---|---|
| `atf` | `null` | 无操作 |
| `xsf` | `rv0(dtf,z2,5)` | 清选：`dtfVar.a.a()`+`dtfVar.c.a()`（rv0.java case5） |
| `wsf` | `e8f(dtf,4)` | 取消 deselectMode（P1445 已覆盖） |
| `btf` | `ch1` case8 | ssf→`hmb.g(new lsf(id))`；rsf→`new jsf(...)`；尾部 `dtfVar.e.c(tap, msf)` 起同手势移动会话（r3b，`usf` case0 同族） |
| `ysf` | `d9c` | deselectMode 点除（P1445 已覆盖） |
| `ctf` | `usf` case0 | `r3b` 移动状态机（拖拽） |
| `zsf` | `ch1` case9 | `dtf.d(new zyh(id))` 进文本编辑 + `w8d.d(zsf.b)` 落 caret |

### 关键事实

1. **`zsf`（EnterTextBlock）仅 `lsf` 同元素命中与 `jsf` 非 vvh 组成员命中产生**；
   `isf`（含套索圈中的单文本块）界内点按一律 `ctf` 拖拽，**不进编辑**。
2. `lsf` 支无 `f5n.h` 界内判定——界内命中异元素重选、界内落空清选，
   由命中测试而非选区矩形决定分发。
3. `ch1` case8 尾部 `e.c(tap, msf)` 无条件起移动会话——任何 `btf`
   重选（含选区外命中换选）都使同一手势可拖新选区。
4. `jsf` 非 vvh 组成员命中 → `zsf` → `zyh(非文本 id)` → 文本控制器
   无法绑定 → 实际为消费 no-op（不拖拽）。
5. 编辑会话激活（`r3eVar.F≠null`）且 `z2` 时，同块点按 → `atf`；
   `z2` 早退支（vsf）：编辑中点选区外 → 退编辑。

## Harmony 对齐（`note/src/main/ets/ui/editor/NoteCanvasView.ets`）

| 原版 | Harmony | 落点 |
|---|---|---|
| lsf 同 vvh 命中 → zsf 进编辑+caret | `insideOverlayElementTap` lsfLike 支 → `linkHitOnTextBlock`/`beginTextEditingAt`（`caretIndexAtPoint` = w8d.d 等价） | ~1480 |
| lsf 界内落空 → xsf 清选 | lsfLike 支 `insideHitId===null` → `clearSelectionWithRegisterReset()` | ~1469 |
| lsf 界内异命中 → btf 重选+e.c | lsfLike 支 → `applyTapSelect` + `beginSelectionDragSession(canvasP, screenP)` | ~1474 |
| lsf 同非 vvh → ctf 拖拽 | lsfLike 尾 `return false` → `beginSelectionDragSession` | ~1492 |
| isf 界内（含单文本）→ ctf | `!lsfLike` → 落拖拽（编辑激活只在 lsfLike 内） | ~1494 |
| jsf 非 vvh 成员 → zsf 消费 | 组支 `leaves.indexOf>=0` → `return true` 消费 | ~1494 |
| 选区外命中 → btf 重选+e.c | 两处 `applyTapSelect(hitId)` 补 `beginSelectionDragSession` | ~3706/3838 |
| 编辑会话激活 → atf/vsf | `textEditing` 门先于选区分发（3596-3608） | 3596 |
| 裸笔压制 `!z3` | `stylusSuppress`（SourceTool.Pen ≈ 裸笔，fail-closed） | 3664 |
