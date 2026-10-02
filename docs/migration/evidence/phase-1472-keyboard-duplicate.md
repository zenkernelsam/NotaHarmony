# Phase 1472 — Ctrl+D 复制选区（f2 兜底链 → xc8 byte1 → ot2.a）

- **阶段**: Phase 1472
- **日期**: 2026-08-10
- **原版版本**: decompiled_1.4.2（APK `com.gingerlabs.notability` 1.4.2）
- **Harmony 落点**: `NoteCanvasView.ets` `onCanvasKeyEvent` →
  `SelectionMenuAction.DUPLICATE` → `duplicateSelected(...)`

## 原版证据链

### 键码与分发支（pa8.java / f2.java:219-227）

```java
// pa8.y = ofk.e(32) = KEYCODE_D
if (db8.r(keyEventB)) {                          // 只查 Ctrl
    if (pa8.a(db8.n(keyEventB), pa8.y) &&
        lxm.a(db8.o(keyEventB), 1) &&            // action == UP
        (msfVar2 = (msf) d63Var.f.F.getValue()) != null) {  // 选区非空
        tee.I(bd8Var4.z(), null, null,
            new xc8(bd8Var4, msfVar2, null, b2=1), 3);
    }
}
```

- `db8.r` = Ctrl 必需；**无 `db8.q`(Alt) / `db8.s`(Shift) 排他门**——
  Ctrl+Shift+D、Ctrl+Alt+D 原版同样触发复制。
- 支内无 `b2=0` 回落：DOWN 与「无选区 UP」均**消费不动作**。
  无选区 UP 走 `else` 推 `qc8.a` 单例空事件（qc8.java — `tc8`
  标记接口的无操作实现）。
- 选区谓词 = `msf != null`（`d63.f` 流的当前 Selection 对象，
  提交后非空；进行中套索不置位）。

### 路由与语义（xc8.java / ot2.java）

```java
// xc8 — byte 字段分发：b2=0 → ot2.e(msf)（Ctrl+X cut 支），
//                      b2=1 → ot2.a(msf)（本支 duplicate）
// ot2.a(msf):
//   lt2 负载构建（选中元素打包）→ ome.a() 清原选区
//   → f(jt2, 选区中心 + min((sbe.c−sbe.a)*0.1, 30) 双轴等值) 粘贴副本
```

- `f2.java:333-345` 的 Ctrl+V 邻近支内联同款偏移式佐证：
  `fMin2 = Math.min((sbe.c - sbe.a) * f /*0.1*/, 30.0f)`，
  `jA7 = center + (fMin2, fMin2)`——副本向右下错开。
- `xc8` 与 `yc8`/`zc8`（COPY/CUT 键盘支）共用 `ea1` 事件通道。

## Harmony 移植

`note/src/main/ets/data/OriginalKeyboardChords.ets`：

```ts
export const ORIGIN_KEYCODE_D: number = 2020;  // pa8.y = ofk.e(32)
```

`note/src/main/ets/ui/editor/NoteCanvasView.ets` `onCanvasKeyEvent`
`!textEditing` 块内、digit 工具选择支之前：

```ts
if (ctrl && event.keyCode === ORIGIN_KEYCODE_D) {
  if (isUp && this.selectionTool.getState().isActive) {
    this.onSelectionMenuAction(SelectionMenuAction.DUPLICATE);
  }
  return true;
}
```

- `ctrl` 为 `keyChordCtrl` 持有即真（无 shift/alt 排他）——等价原版
  只查 `db8.r`。
- `isActive` ≈ `msf != null`：进行中空套索下 `duplicateSelected`
  经 `copySelectedToClipboard` 空 id 集返回 false 安全 no-op，
  与 `qc8` 空事件语义一致。
- `return true` 无条件消费 —— DOWN/无选区不动作但吞键。

### 复用管线（duplicateSelected）

`copySelectedToClipboard`（lt2 负载等价）→ `selectionPasteTarget()`
（选区中心）→ `nudge = min(rectWidthCanvas*0.1, 30)` 页面单位 →
`pasteClipboard(center + (nudge,nudge))`——与 `ot2.a` 逐步对应；
清原选由粘贴路径既有清选语义承载。

## 差异与残余

- 原版经 `xc8` 协程异步执行；Harmony 走既有同步粘贴管线，
  结果等价（undo/persist 均入）。
- 进行中套索期间 `isActive=true` 但 id 全空 → no-op，与原版
  `msf==null → qc8` 输出一致。

## 验证

- Replay `d02-original-selection-duplicate-key.mjs`：23 checks
  （键码 pin、Ctrl 门、UP+选区门、无修饰排他、消费语义、
  DUPLICATE 管线、偏移可执行模型）。
- 相关键盘 fixture 全绿（delete/nudge/page-key/media/shortcuts）。
- `note@default` + `note@ohosTest` clean 构建成功。

## 关联

- ADR-1407-keyboard-duplicate
- 报告 `docs/migration/reports/phase-1472-keyboard-duplicate.md`
