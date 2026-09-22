# 原版证据：选区菜单 DESELECT = deselectMode（点按移除模式）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 591 依据。

## 1. 菜单项定义

- `dsc.java:71-73`：选区菜单动作枚举 ordinal 20 = `DESELECT`。
- `ux9.java:2396-2398`：渲染 `feature_note__selection_menu_deselect`
  （文案 "Deselect"）+ `circle_minus` 图标。

## 2. 进入模式（`dhb.java` case20）

```java
case 20:                                  // dsc.DESELECT
    ftc ftcVar2 = fvbVar.h.getValue() as ftc;
    if (ftcVar2 != null) {
        fvbVar.n = ftcVar2;                // 保存进入前快照（取消时恢复）
        fvbVar.a.d(ftc.j(ftcVar2, …, true, …, 16255));   // deselectMode=true
    }
    xscVar.M.a();
```

`ftc.h` = deselectMode、`ftc.i` = deselectedIds、`fvbVar.n` = 进入前的
`ftc` 快照。

## 3. 模式内 pointer-down（`dl1.java` case2，`h=true` 分支）

- `xtc.a(jE, set)` 命中 ∈ 选中集的元素 → `stc({id})`；
- `ntc`/`cqc` 组命中（组内任一成员 ∈ 集）→ `stc(cqc.b, cqc.a)` 整组移除；
- 覆盖层 `cmb` 内非元素命中 → `utc`（消费无动作，模式保持）；
- 其余（覆盖层外）→ `qtc`（toString="CancelDeselectMode"）→ `z39(17)`。

## 4. 点按移除语义（`ej9.java` case18）

```java
ys2.H(ftcVar.g, set5)   // selectedIds −= 命中集
ys2.J(ftcVar.i, set5)   // deselectedIds += 命中集
ftcVarJ.g.isEmpty() → fvbVar.a()   // 选中集清空 → 退出选区
```

## 5. 退出路径

- `z39.java` case17（qtc 取消）：`fvbVar.n` 恢复进 `fvbVar.a.d(...)` —
  **点空处取消整个 deselect 会话并恢复进入前快照**。
- `n6d.java` case11/12：`k2f.onConfirmDeselectMode()` /
  `onCancelDeselectMode()` —— 模式有显式确认/取消 UI；
  onConfirm 保留缩减选区，onCancel 恢复快照。
- `ac4.java:105`：`DESELECT_MODE` 同时也是特性开关名（`isb.c`
  "androidDeselectMode"）；`op8` 含 `kbd_shortcut_dismiss_deselect`
  键盘快捷键——模式另有键盘入口。

## 6. Harmony 对齐（Phase 591）

| 原版 | Harmony |
|---|---|
| dsc.DESELECT 菜单（Deselect + circle_minus） | `SelectionMenuAction.DESELECT`（标签 `deselect` 字符串）→ `enterDeselectMode()` |
| `fvbVar.n` 快照 | `SelectionTool.preDeselectSelection`（六类 id 快照） |
| `stc`/case18 元素/组移除 | `deselectElements(entityIds, groupIds)`：移出 selected* 并入 deselectedIds；组经 `resolveOriginalSelectedGroupLeaves` 整组移除并剔除 selectedGroupIds |
| `g.isEmpty` → 退出 | 全部 selected* 为空 → `deselect()` |
| 覆盖层内非元素 → `utc` | 覆盖层内未命中 → no-op |
| `qtc`/`z39(17)` 点空取消恢复 | 覆盖层外未命中 → `cancelDeselectMode()` 恢复快照 |
| `k2f` onConfirm/onCancel | deselectMode 下 ⋯ 菜单换为 Done(confirm)/Cancel 两项 |

## 7. 有界偏差

- 原版的 deselectMode 确认/取消是 `k2f` 专用 UI 条（非 ⋯ 菜单项）；
  Harmony 复用 ⋯ 菜单承载两项，语义等价、呈现不同。
- `ntc` 动态组命中中"命中未选中但组内成员被选中"路径依赖查询期
  `cqc` 聚合；Harmony 只对持久 `selectionGroups` 展开——该组一旦被
  选中其叶子必全部选中，故未选中成员命中在静态模型下不可达。
- 键盘快捷键入口（`androidDeselectMode`）未移植——Harmony 版无硬件
  键盘快捷键层。
