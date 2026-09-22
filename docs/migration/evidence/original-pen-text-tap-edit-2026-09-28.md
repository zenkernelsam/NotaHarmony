# Evidence — TEXT 面裸笔点按文本块直接编辑（zl2 case25）

- 日期：2026-09-28；Phase 623
- 来源：`decompiled_1.0.3/sources/defpackage/{zl2,xtc,tl7,dl1}.java`

## zl2.java case25（TEXT 面点按分发，zl2.java:191-211）

```java
long jE = ((i3a) obj2).e(((zn9) obj).a);
qo5 qo5VarC = xtcVar.c(jE);          // xhe 过滤命中（文本元素）
if (qo5VarC != null) {
    qkeVar = new qke(qo5VarC);       // 直接编辑会话产出
} else {
    x09 x09VarC = xtcVar.a.c();
    if (x09VarC != null && tl7.w(x09VarC, ei3.f(jE))) {
        return null;                 // 命中含链接行 → 吞掉
    }
    qkeVar = oke.a;                  // 落空 → 提交/销毁会话
}
xtcVar.b.a();                        // 重置手势会话
uke.d(ukeVar, qkeVar, false, 2);     // 分发给文本会话协调器
```

- `xtc.java:76`：`c(j)` = `vnd` 命中过滤 `instanceof xhe`——只命中
  文本承载元素（文本块/数学块），返回 `qo5` id。
- `tl7.java:823`：`w(page,y)` = y 处文本行解析出链接内容
  （`nz9.B().l() != null`）→ true → 吞掉（链接自身处理器接管）。
- `dl1.java:87`：`z && !elh.h`（`elh.h`=工具标志∧工具类型1 或
  桶键位 66）→ `z3=false`：rtc/vtc 选区命中压制为 utc——
  **裸笔点按不走选区分发，落空交还文本手势面（case25）**。

## 语义结论

原版 TEXT 面（文本工具/文本编辑活跃面）：

- **裸笔点按文本块** → `qke` 直接编辑（单笔点按即入编辑态，
  不需双击、不经选区）。
- **裸笔点按链接行** → 吞掉（链接处理器接管）。
- **裸笔点按空白** → `oke.a`（提交/销毁会话；创建经其他手势）。
- **手指点按** → `elh.h` 允许时选区分发照常（vtc 选中）。

## Harmony 对齐前差距

DEFAULT（文本面）下裸笔点按文本块：`stylusSuppress` 跳过选区
分发后落入双击计时器——已存在文本块也需第二击才进入编辑，
与原版单笔 `qke` 直接编辑不一致。

## Harmony 对齐（NoteCanvasView.ets DEFAULT 分支）

- `stylusSuppress` 分支（双击计时器之前）：顶层优先
  `pointHitsTextBlock` 循环（xhe 过滤等价）——
  - 命中文本块且 `linkHitOnTextBlock == null` →
    `lastTapTime=0` + `beginTextEditingAt` 直接编辑（qke 等价）。
  - 命中文本块但命中链接行 → 吞掉 return（tl7.w 等价）。
  - 未命中 → 保持双击创建路径（oke.a 落空吞掉的移植等价）。
- 手指点按仍经 `!stylusSuppress` 选区分发（vtc），不经此支。

## 验证

- `d02-original-pen-text-tap-edit.mjs`：11 断言全绿。
- `d02-original-text-surface-selection-dispatch` /
  `selection-tap-clear` / `recent-interaction-menu-gate` 全绿。
