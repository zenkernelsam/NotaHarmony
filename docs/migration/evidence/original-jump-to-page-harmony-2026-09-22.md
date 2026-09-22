# Phase 542 — 原版跳转到页（Jump to Page）（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/editor/PageManagerBar.ets`、`NotePage.ets`、
双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

### 页指示器可点击（`n8.java` case 20）

```java
String strT = tl7.T(R.string.feature_note__page_indicator,
    new Object[]{Integer.valueOf(i2), Integer.valueOf(list.size())}, uz4Var);
pd8 pd8VarJ = aa6.j();            // ripple indication
l5c l5cVar = new l5c(0);
Object objS = uz4Var.S();
if (objS == sh8Var) {
    objS = new g89(gl8Var, 25);   // 点击 lambda：置 jump-dialog 可见态
    uz4Var.p0(objS);
}
tpe.b(strT, dac.m(uz4Var, uz4Var,
    m18.K(pd8VarJ, false, null, l5cVar, (Function0) objS, 11),  // clickable modifier
    12.0f, 8.0f), j, ...);
```

`page_indicator`（"N / M"）文本经 `m18.K(...)` clickable 修饰符链包裹，
点击回调 `g89(gl8Var, 25)` 打开跳转对话框——指示器本身即入口，无独立按钮。

### 对话框组成（`ke1.java`）

- `ke1.java:164`：`feature_note__jump_to_title` 标题。
- `ke1.java:174`：`feature_note__jump_to_page_label` 页码输入框标签。

### Go 启用条件（`n8.java` case 21）

```java
String strU = tl7.U(uz4Var2, R.string.feature_note__jump_to_go);
Integer numP0 = svd.p0((String) gl8Var2.getValue());   // 解析输入为整数
boolean z = numP0 != null && 1 <= (iIntValue = numP0.intValue()) && iIntValue <= i2;
v3j.a(null, strU, null, false, z, ...);                 // enabled = z
```

`svd.p0` 将输入解析为 `Integer`（失败为 null）；Go 按钮 `enabled` 当且仅当
解析成功且 `1 <= n <= pageCount`。

## Harmony 落地

`PageManagerBar`：

- 页指示器 `Text("current / total")` 加 `.onClick`——`busy ||
  photoImportLeaseActive` 时 fail-closed 直接 return（与兄弟回调同款守卫），
  否则 `jumpDialog.open()`；`.enabled(!busy && !lease)` 同步禁用视觉。
- `JumpToPageDialog`（`@CustomDialog`）：`jump_to_title` 标题 +
  `TextInput`（`InputType.Number`，`jump_to_page_label` 占位，初始值=当前页）
  + Cancel/Go 按钮行。`targetPage()` 以 `parseInt`+严格整串比对复刻
  `svd.p0`；`goEnabled()` = `1 <= n <= pageCount`（n8 case 21 对齐）；
  Go 点击二次校验范围后回调 `onGo(target - 1)`（0 基索引）并关闭。

`NotePage`：`onJumpToPage` 回调走与 prev/next 相同的守卫集
（`pageLoading`、`pageOperationBusy`、`historyPending`、
`pageStructureLeaseActive`）+ 边界检查，合法时赋 `currentPageIndex`。

字符串：`jump_to_title`/`jump_to_page_label`/`jump_to_go` 双语
（取消复用既有 `cancel`）。

## 差异登记

- 原版指示器无独立图标，Harmony 以 `accessibilityText` 标注可点性——
  语义等价。
- `JumpToPageDialog` 用 ArkUI `CustomDialogController`（模态）替代原版
  Compose `AlertDialog`；`autoCancel` 对应点击外部关闭。
- `svd.p0` 的解析语义（trim 后整串十进制）以 `parseInt`+整串比对复刻，
  拒绝 "12abc"、"1.5" 等非整串输入。
