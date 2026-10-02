# ADR-1407: Ctrl+D 复制选区（f2 → xc8 byte1 → ot2.a 通道）

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1472
- **关联**: evidence/phase-1472-keyboard-duplicate.md
  （`f2:219-227`/`xc8`/`ot2.a`/`qc8` 解码）

## 背景

原版键盘兜底链在 `!pa8.W` 块内实现 Ctrl+D 复制选区：
Ctrl（`db8.r`）按住时键码 D（`pa8.y`，Android KEYCODE_D=32）
命中，UP 动作且 `msf != null` → `xc8` 事件（byte=1）→
`ot2.a(msf)`：lt2 负载构建 → `ome.a()` 清原选 → 选区中心 +
`min(宽*0.1, 30)` 双轴等值偏移粘贴副本。Harmony 已有完全同核的
`duplicateSelected`（菜单 DUPLICATE 管线），缺键盘入口。

## 决策

- `OriginalKeyboardChords` 新增 `ORIGIN_KEYCODE_D=2020`。
- `NoteCanvasView` `onCanvasKeyEvent` `!textEditing` 块内、
  digit 工具选择支之前新增支：

  ```ts
  if (ctrl && event.keyCode === ORIGIN_KEYCODE_D) {
    if (isUp && this.selectionTool.getState().isActive) {
      this.onSelectionMenuAction(SelectionMenuAction.DUPLICATE);
    }
    return true;
  }
  ```

- 复用 `SelectionMenuAction.DUPLICATE` → `duplicateSelected`
  管线，不引入第二套复制实现。

## 等价性论证

| 原版 | Harmony | 一致性 |
|------|---------|--------|
| `db8.r` 必需，无 alt/shift 排他 | `ctrl` 持有即真，条件无 shift/alt | ✓ |
| UP 触发（`lxm.a(o,1)`） | `isUp` 门 | ✓ |
| `msf != null` 选区谓词 | `selectionTool.getState().isActive` | ✓ |
| DOWN 消费不动作（支内无 b2=0） | 无条件 `return true` | ✓ |
| 无选区 UP → `qc8.a` 空事件消费 | 同支消费，`duplicateSelected` 空集 no-op | ✓ |
| `min(w*0.1, 30)` 双轴偏移 | `Math.min(rectWidthCanvas*0.1, 30)` 同式 | ✓ |
| `ot2.a` = 负载→清选→偏移粘贴 | `duplicateSelected` = copy→target→paste | ✓ |

## 边界

- 进行中套索 `isActive=true` 但选中 id 全空：原版此时 `msf==null`
  → `qc8` 空事件；Harmony `duplicateSelected` 经
  `copySelectedToClipboard` 空集返回 false 早退——输出等价。
- 原版经 `xc8` 协程异步；Harmony 同步粘贴管线，结果等价。

## 验证

- `d02-original-selection-duplicate-key.mjs`：23 checks。
- 键盘 fixture 组全绿；`note@default`/`note@ohosTest` clean 构建成功。
