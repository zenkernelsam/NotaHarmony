# 原版证据：文本块按下点光标定位（ttc → qke + sqa）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 609 依据。

## 1. ttc 事件产出（dl1.java）

`dl1` case2 中 `ttc(qo5 blockId, long jE)` 在两处产出，均携带
按下点世界坐标 `jE`：

- **dl1.java:327-330（itc 单元素选区）**：点按命中元素与已选
  单元素同 id（`ba6.o(itcVar.a, ly3Var2.getId())`）且
  `(!z2 || ufb.I == null)`（非 TEXT 面 / 无编辑会话）时：

```java
ttcVar = ly3Var2 instanceof xhe ? new ttc(ly3Var2.getId(), jE)
                                : new wtc(ys2.x(vnd.b(vndVar2)), itcVar);
```

即**已选中的文本块（xhe）被再点一次 → ttc**；非文本 → wtc 拖拽。

- **dl1.java:222-226（gtc 组选区）**：命中非 `xhe` 的组内成员
  时产出 `ttc`（消费该按下，不拖拽）；命中 `xhe` 或非成员 → wtc。

## 2. ttc 消费（uw2.java:138-151 case4）

```java
xtcVar2.d(new qke(ttcVar.a), true, z);            // 激活该块编辑器
ake akeVar = (ake) xtcVar2.e.t.I.getValue();
if (akeVar != null && (ekeVar = akeVar.r) != null
        && (yqaVar = ekeVar.h) != null) {
    long j = ttcVar.b;                            // 按下点世界坐标
    uub uubVar = (uub) yqaVar.a.getValue();
    if (uubVar != null) {
        yqaVar.g.m(new sqa(
            rej.i(zn9.f(j, uubVar.f), uubVar.e),  // 世界→局部→偏移
            0));
        yqaVar.b.b(new tqa(uubVar, 0));           // 链接/标注探测
    }
}
```

- `qke(qo5)`：`uke.d`（uke.java:258-268）从挂起会话表 `uke.p`
  按块 id 取 `ake` 激活（不存在则记 "Cannot activate text
  editor" 并置空）。
- `sqa`：把 `zn9.f(j, uub.f)`（世界点逆变换进块局部系）经
  `rej.i`（布局偏移命中，Compose `getOffsetForPosition` 等价：
  最近行钳制 + 半字宽拆分）转为文本偏移，**无条件**把光标
  定位到按下字符处——覆盖 qke 恢复的挂起光标。
- `tqa`：对命中处做链接/标注探测。

## 3. Harmony 缺口与修复

- 旧实现 `beginTextEditingAt` 激活编辑时只恢复
  `suspendedCaretByBlock` 挂起光标（无会话 → TextArea 默认位），
  不按按下点定位——已选文本块二次点按后光标不落在点按字符处，
  与原版 sqa 语义不符。
- 修复：
  1. `Canvas2DTextRenderer.caretIndexAtPoint`：复用
     `linkAtPoint` 同一套 `inverseTransformPoint` + `layoutLines`
     + `characterIndexAt` 机制（rej.i 等价）——y 轴钳到最近行带，
     x 轴行内半字宽拆分，越过行尾 → `line.end`，空文本 → 0。
  2. `beginTextEditingAt`：qke 恢复挂起光标后立即计算
     `tapCaret`，非空则覆盖 `textEditingRestoreCaret`/
     `editingCaretOffset`（sqa 无条件定位语义）；该路径同时覆盖
     `insideOverlayElementTap`（itc→ttc 等价）与 TEXT 面点按。
  3. `TextBlockOverlay.onAppear` 既有
     `caretPosition(restoreCaret)` 落位消费不变。
  4. 链接命中（`linkHitOnTextBlock`，tqa 等价）仍在编辑激活
     之前——点中链接开菜单而非进入编辑。
