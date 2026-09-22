# 原版证据：文本编辑中块外点按 → 提交并停用（oke.a）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 594 依据。

## 1. TEXT 工具点按面（`zl2.java` case25）

`zl2` case25 由 `ha5` case0（`PointerInputEventHandler`）经 `e5j`
挂到画布——即原版 TEXT 工具的点按处理：

```java
long jE = ((i3a) obj2).e(((zn9) obj).a);          // 画布点按
qo5 qo5VarC = xtcVar.c(jE);                        // 命中文本块
if (qo5VarC != null) {
    qkeVar = new qke(qo5VarC);                     // 命中块 → 激活编辑器
} else {
    x09 x09VarC = xtcVar.a.c();
    if (x09VarC != null && tl7.w(x09VarC, ei3.f(jE))) {
        return null;                                // 点按在当前编辑块内 → 保持
    }
    qkeVar = oke.a;                                 // 块外 → 停用编辑器
}
uke.d(ukeVar, qkeVar, false, 2);
```

## 2. `oke.a` 停用语义（`uke.java`）

`uke.d` 对 `oke.a`：`asdVar` CAS 把活动文本块编辑器（`ake`）置空——
提交当前内容并退出编辑态。`pke.a` = 清空草稿；`qke(id)` = 激活指定块
（Phase 593）。

## 3. 挂接位置（`e5j.java:291-310`）

TEXT 工具的点按面（`ha5`）以 `PointerInputEventHandler` 附着画布，
先于笔迹工具分发——点按只驱动编辑器激活/停用，不产生笔迹。

## 4. Harmony 对齐（Phase 594）

- `onTouchDown` 头部（`clipboardPasteTarget` 之后、工具分发之前）：
  `textEditing && editingTextBlock !== null` 时——
  - `pointHitsTextBlock(canvasP, editingTextBlock)` 块内 → `return`
    （TextArea 自理，对齐 `tl7.w` 保持编辑）；
  - 块外 → `onTextCommit(editingDraftText)`（尾部
    `textEditing=false; editingTextBlock=null`，即 `oke.a` 提交+停用）
    并消费该次点按。
- 对齐原版"点按只驱动编辑器、不落到笔迹"的消费语义——本次点按
  不触发套索/笔迹/选区；下一次点按才按当前工具正常分发。

## 5. 有界偏差

- 原版点按块外另一文本块 → `qke(id)` 直接切换激活块；Harmony 统一
  走"提交停用"，随后点按再由各工具路径（双击/`itc`）重新进入编辑
  ——多一次点按，行为近似。
- 原版 `zl2` 属 TEXT 工具专属面；Harmony 将块外停用挂在所有工具的
  `onTouchDown` 头部——编辑态跨工具保持一致（原版编辑表面亦全局
  挂接，语义等价）。
- `onTextCommit` 为异步提交（原版 `oke.a` 同步 CAS）；`historyBusy`/
  `photoImportBusy` 守卫下提交被拒绝时编辑保持——与原版的并发
  保护等价。
