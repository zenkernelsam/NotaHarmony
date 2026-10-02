# Phase 1469 — Delete / Forward Delete 键盘删除选区（f2 → go(bd8,msf) 通道）

- **阶段**: Phase 1469
- **日期**: 2026-08-10
- **原版版本**: decompiled_1.4.2（APK `com.gingerlabs.notability` 1.4.2）
- **Harmony 落点**: `note/src/main/ets/ui/editor/NoteCanvasView.ets`
  `onCanvasKeyEvent`；`note/src/main/ets/data/OriginalKeyboardChords.ets`

## 原版证据链

### 键码（f2.java 静态区 + pa8.java）

```
f2.java:40-60  ——  pa8.O = ofk.e(67)；pa8.P = ofk.e(112)。
pa8.java     ——  ofk.e(N) 把 Android 键码包装成 pa8 值对象。
```

- Android `KEYCODE_DEL = 67`（Backspace）、`KEYCODE_FORWARD_DEL = 112`。
- Harmony 键码（`@ohos.multimodalInput.keyCode.d.ts`）：
  `KEYCODE_DEL = 2055`、`KEYCODE_FORWARD_DEL = 2071`。

### 分发支（f2.java:247-253）

```java
} else if (pa8.a(db8.n(keyEventB), pa8.P) || pa8.a(db8.n(keyEventB), pa8.O)) {
    if (!lxm.a(db8.o(keyEventB), 1) || (msfVar = (msf) d63Var.f.F.getValue()) == null) {
        b2 = 0;
    } else {
        tee.I(bd8Var4.z(), null, null, new go((byte) 14, null, bd8Var4, msfVar), 3);
    }
}
```

- 该支位于兜底链 `!(Q.m instanceof rsi)` 门内（非文本编辑态才接管），
  且嵌在 `!pa8.a(n, pa8.W)` 块内（`pa8.W = ofk.e(279)`；对 DEL/FDEL
  键码恒真，相当于无额外门）。
- **无修饰键门**——分支谓词只测键码，`db8.r`(Ctrl)/`db8.s`(Shift)
  均不参与：Ctrl+Del、Shift+Del 同样删除。
- **动作门**：`lxm.a(o,1)` = 仅 KeyUp 触发；Down（含长按重复）不消费。
- **选区门**：`d63Var.f.F.getValue()` = 当前 `msf` 选区；为空 → `b2=0`
  不消费透传（让系统/文本控件处理退格等语义）。
- 消费路径：`bd8.z()` 协程作用域启动 `go(byte14, bd8, msf)`。

### 删除协程（go.java invokeSuspend case 14，bytecode 转储 L28a-L2e0）

`invokeSuspend` 整体超 jadx 反编译阈值（2682 指令单元），经
`--comments-level debug` 转储逐指令解码：

```java
w0g w   = (w0g) wib.a.i0();                          // 当前页文档句柄
List el = oag.x2(q9l.a(e52.i4(msf.h()), em4.F, em4.F, em4.F));
                                                    // 选中 id 集→元素引用
fq9.c0(w, el, bd8.I /* ofj */, fm4.F);               // 批量删除（挂起）
bd8.L.a();                                           // ome.a() 清选
```

- `msf.h()` 返回原始选中 id 集（`isf.g`/`lsf.a`/`jsf.b`/`ksf`；
  `hsf`=空集）——分发层**不滤锁定元素**。
- `fq9.c0`（fq9.java:765）把每个 `qph` 元素包成 `g1c(qph,null,false,null,30)`
  后走 `d0` 批处理——删除+撤销事务一次提交。
- `ome.a()`（ome.java:39）：`m=null; a.g(null)` = 清除选区状态。

### 菜单 DELETE 同核验证（sqf.java case 10 / urf.E）

```java
// sqf case10 (wqf.P = DELETE, ordinal 10)
tee.I(urf.z(), p2d(byte24, urf, msf.h()));           // → urf.E(list)
urf.H.a();                                          // 清选/关菜单

// urf.E body
w0g w = wib.a.i0();
fq9.c0(w, list /* = oag.x2(q9l.a(i4(ids), em4.F×3)) */, K /* ofj */, fm4.F);
```

- 菜单 DELETE 与键盘 DEL 解析后的核心调用**完全相同**：
  `wib.a.i0()` + `fq9.c0(w0g, elements, ofj, fm4.F)` + 清选。
- 结论：键盘支可直接复用 Harmony 的菜单 DELETE 管线，无需另起删除逻辑。

## Harmony 实现

`OriginalKeyboardChords.ets` 新增：

```ts
export const ORIGIN_KEYCODE_DEL: number = 2055;
export const ORIGIN_KEYCODE_FORWARD_DEL: number = 2071;
```

`onCanvasKeyEvent` 的 `!this.textEditing` 兜底块内（DPAD nudge 支之后）：

```ts
if (event.keyCode === ORIGIN_KEYCODE_DEL ||
  event.keyCode === ORIGIN_KEYCODE_FORWARD_DEL) {
  if (!isUp || !this.selectionTool.getState().isActive) {
    return false;            // f2 b2=0：不消费透传
  }
  this.onSelectionMenuAction(SelectionMenuAction.DELETE);
  return true;
}
```

- `isUp` 门 = `lxm.a(o,1)`；`isActive` = `d63.f != null`。
- `return false` 支同时覆盖 Down 与无选区——原版 `b2=0` 透传。
- 复用 `onSelectionMenuAction(DELETE)`：收集 `msf.h()` 等价 id 集 →
  删除元素 → `DELETE_ELEMENTS`/`DELETE_STROKE` 撤销步 → 持久化 →
  `clearSelectionWithRegisterReset()`（`ome.a()` 等价）。

## 差异与边界

- 原版 `fq9.c0` 经 `ofj`（分析/遥测）埋点——Harmony 无对应遥测，已登记。
- 原版锁定元素由 `fq9.d0` 内部或选区构建层处理；Harmony DELETE 管线
  同样不额外过滤（与 `msf.h()` 原始 id 集语义一致；CUT 支的
  `clipboardSelectionWithoutLocked` 过滤属于 `lg2.d` 剪贴板语义，不波及）。
- 文本编辑中 DEL 透传给文本控件——`!textEditing` 门等价 `!rsi`。

## 验证

- `docs/migration/replays/d02-original-selection-delete-key.mjs`：17 项——
  键码 pin、证据注释 pin、分发结构 pin（无修饰门/UP+选区门/透传）、
  链序 pin、`DELETE` 管线复用 pin、可执行门控模型（4 例）。
- 全部键盘 fixture 无回归；`note@default`、`note@ohosTest` 构建通过。
