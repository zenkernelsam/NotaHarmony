# Phase 1475 — Ctrl+Shift+M/I 插入和弦（f2:240-247）

## 原版证据（decompiled_1.4.2）

### 键码字段

`pa8.java`：

- `pa8.D = ofk.e(41)` → Android `KEYCODE_M`（Harmony `KEYCODE_M = 2029`）
- `pa8.C = ofk.e(37)` → Android `KEYCODE_I`（Harmony `KEYCODE_I = 2025`）
- 注意字段名与键码字母不一致：`pa8.D` 对应键 **M**，`pa8.C` 对应键 **I**。

### 分发支（`f2.java` 兜底链，`!rsi` 文本编辑门内、`!pa8.W` 块内）

```
240  if (db8.r && db8.s && pa8.a(n, pa8.D)          // Ctrl+Shift+M
        && u7b.g 键盘使能旗
        && lxm.a(action, 1)) {                       // KeyUp
      ea1Var.p(mc8.a);                               // InsertMath
      }
244  if (db8.r && db8.s && pa8.a(n, pa8.C)          // Ctrl+Shift+I
        && u7b.g
        && lxm.a(action, 1)) {
      ea1Var.p(nc8.a);                               // InsertPhoto
      }
```

- `db8.r` = Ctrl、`db8.s` = Shift（`db8.java` 修饰键谓词）。
- `lxm.a(action, 1)` = KeyUp 判定；两支 `return` 前无 `b2=0` →
  DOWN 亦消费（吞键不动作）。
- `u7b.g` = `ec2.e0` 组合状态旗，默认 `Boolean.TRUE`
  （`k59.t` stylus/hw 组合 + `yah.m` 派生）——键盘组合使能旗，
  P1468 已登记"Harmony 以恒真近似"差异。
- 链序：Ctrl+D(221) → Ctrl+Shift+T(230) → **Ctrl+Shift+M(240)** →
  **Ctrl+Shift+I(244)** → DEL(247) → PAGE_UP(254) → PAGE_DOWN(259)。

### 事件语义

- `mc8.java`：`tc8` 事件单例，`toString() = "InsertMath"`；
  `ea1.p(...)` 进入事件总线，消费端打开数学插入 UI。
- `nc8.java`：`toString() = "InsertPhoto"`；消费端打开图片
  导入管线（系统图片选择器）。

## Harmony 移植

`NoteCanvasView.onCanvasKeyEvent` `!textEditing` 块内（DPAD nudge
支后、DEL 支前，与 f2 链序一致）：

- `ctrl && shift && (KEYCODE_M | KEYCODE_I)` → `isUp` 时调
  `onKeyInsertMath()` / `onKeyInsertPhoto()`；无条件 `return true`
  （DOWN 消费不动作）。
- `NotePage` 接线：与工具栏 `onInsertMath`/`onInsertPhotos`
  同一管线——
  - `onKeyInsertMath` → `mathInsertSignal++`；
  - `onKeyInsertPhoto` → `photoImportLeaseActive = true` +
    `photoInsertSignal++`；
  - 同租约门：`photoImportLeaseActive` / `pageOperationBusy` /
    `historyPending` / `pageStructureLeaseActive` 任一活跃即吞键。

## 差异登记

- `u7b.g` 键盘组合使能旗：原版组合旗（stylus/hw 状态派生），
  Harmony 恒真近似（P1468 同例登记）。
- 消费侧是事件总线（`ea1.p`），Harmony 直调同一插入管线——
  语义等价。

## Replay

`docs/migration/replays/d02-original-insert-keys.mjs`（19 checks）。
