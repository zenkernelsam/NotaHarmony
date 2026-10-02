# Phase 1472 报告：Ctrl+D 复制选区（xc8 byte1 → ot2.a 通道）

## 原版行为（1.4.2 证据）

键盘兜底链 `f2.java:219-227`（`!rsi` 非文本编辑门内、`!pa8.W` 块内）：

- **Ctrl+D**（`db8.r` + `pa8.y`=KEYCODE_D=32）：UP 动作且
  `msf != null`（`d63.f` 当前选区对象）→ `tee.I` 发
  `xc8(bd8, msf, null, b2=1)`。
- `xc8` 按 byte 分发：`b2=1` → `ot2.a(msf)` = **Duplicate**；
  `b2=0` 支（Ctrl+X）→ `ot2.e` = cut。
- `ot2.a` 语义：lt2 负载构建 → `ome.a()` 清原选 → 选区中心 +
  `min((sbe.c−sbe.a)*0.1, 30)` 双轴等值偏移粘贴副本
  （`f2:333-345` 邻近支内联同款偏移式佐证）。
- **消费语义**：支内无 `b2=0` 回落——DOWN 与「无选区 UP」均
  消费不动作（无选区走 else 推 `qc8.a` 单例空事件）。
- **修饰键**：只查 `db8.r`(Ctrl)，无 `db8.q`(Alt)/`db8.s`(Shift)
  排他——Ctrl+Shift+D、Ctrl+Alt+D 原版同样复制。

## Harmony 缺口

`duplicateSelected` 管线（copy→中心→`min(w*0.1,30)` 偏移粘贴）
已完整等价 `ot2.a`，但键盘无 Ctrl+D 入口。

## 实现

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_D=2020`
  （含 pa8.y/xc8/ot2.a 证据注释）。
- `NoteCanvasView` `onCanvasKeyEvent` `!textEditing` 块内、
  digit 工具选择支之前：

  ```ts
  if (ctrl && event.keyCode === ORIGIN_KEYCODE_D) {
    if (isUp && this.selectionTool.getState().isActive) {
      this.onSelectionMenuAction(SelectionMenuAction.DUPLICATE);
    }
    return true;
  }
  ```

- 复用菜单 DUPLICATE 管线——键盘/菜单同核，无双实现漂移。

## 验证

- `d02-original-selection-duplicate-key.mjs`：23 checks 全绿
  （键码/Ctrl 门/UP+选区门/无修饰排他/消费语义/管线 pin/
  偏移可执行模型）。
- 键盘 fixture 组全绿：delete(17)/nudge(18)/page-key(17)/
  media-keys(20)/shortcuts(68)/key-tail(6)。
- `note@default` + `note@ohosTest` clean 构建成功。
- 全量 Replay 基线：见本阶段提交说明。

## 差异

- 原版 `xc8` 协程异步；Harmony 同步管线，结果等价。
- 进行中套索（isActive 但 id 空）触发 → `duplicateSelected`
  安全 no-op，等价原版 `qc8` 空事件。

## 关联

- evidence/phase-1472-keyboard-duplicate.md
- ADR-1407-keyboard-duplicate
