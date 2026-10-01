# Phase 1408 — 页总览 cell 可访问性 + 书签角标交互 + 跳页清除钮

> 证据基线：`decompiled_1.4.2`（cbn.java / ie.java / wq2.java /
> xq2.java / bom.java / or.java / strings.xml）。

## 1. 原版 cell 结构与 a11y 语义

### 1.1 书签角标（cbn.j + ie case2 + fq9.d + wq2）

`cbn.j`（页总览 cell 渲染函数）在缩略图之后、checkbox 之前无条件调用：

```java
fq9.d(function2, t41Var.a(t8aVar, qy0Var), false, null, null,
      k31.L(-603515814, new ie((Object) dr2Var, i12, (byte) 2), nc6Var2), ...)
```

- `fq9.d(Function0, …)` = 可点击图标钮封装——角标是**按钮**而非纯指示。
- `ie` case2：按 `dr2Var.c`（bookmark 标志）双态渲染：
  - `dr2Var.c==true` → `bookmark_tall_fill` + `cd_unbookmark_page_numbered`
    （"Remove bookmark from page %d"）
  - 否则 → `bookmark_tall_outline` + `cd_bookmark_page_numbered`
    （"Bookmark page %d"）
  - 参数 `i12` = cell 显示的页码（`String.valueOf(i12)` 同源）。
  - 图标色 `nta.c(nc6Var).a.d.d.c`（中性图标 token）。
- `function2` 回调 = `xq2` 调用位第 3 参（`wq2` 实例）。`wq2.invoke`：

```java
if (((Boolean) this.I.getValue()).booleanValue()) {   // 选择态
  this.F.D(oag.x2(new cbc(this.G.a)));                // pr2.D(选集{pageId})
} else {                                              // 普通态
  tee.I(this.H, null, null, new pd(this.J, this.K, null, (byte) 2), 3);
  // 协程 njg.b(pageKey, …) → 仓库写路径切换书签
}
```

- `cbc` = `jwf` PageId 值类包装；`oag.x2` = 单元素集构造。
- 即：选择态下角标点击 = 该页并入选中集；普通态 = 切换该书签。

### 1.2 选择态 checkbox（cbn.j `if (z2)` 分支）

```java
if (z3) strV0 = v0(cd_deselect_page_numbered, i12)   // "Deselect page %d"
else    strV0 = v0(cd_select_page_numbered, i12)     // "Select page %d"
f9n.b(w8aVarO, z3, str, …)                            // checkbox(选中态, cd)
```

编号参数同为 `i12`（显示页码）。

### 1.3 选择工具条 icon cd（bom）

`bom` 渲染三枚 `cc3.l` 图标钮（enabled 门控）：

| 图标 | cd |
|------|-----|
| `copy` | `cd_copy_pages` "Copy selected pages" |
| `duplicate` | `cd_duplicate_pages` "Duplicate selected pages" |
| `trash` | `cd_delete_pages` "Delete selected pages" |

（duplicate/delete 仅在 `z7` 真时渲染；more 钮 cd =
`content_manager_more_actions`。）

### 1.4 跳页字段清除钮（or case18）

```java
if (fieldText.length > 0) {
  cc3.l(xmark_circle_fill, w0(cd_clear_page_number), onClick=clear rgaVar, …)
}
```

`ui_designsystem__xmark_circle_fill` = 17×18 evenOdd 矢量：#aab5c6
灰圆底 + 镂空 ×（fillType=evenOdd）。仅在字段非空时渲染，点击清空文本态。

### 1.5 搜索钮激活态 cd

`content_manager_close_search` "Close search" —— 搜索激活时搜索钮的
a11y 描述切换为「关闭搜索」。

## 2. Harmony 落点（本次变更）

| 原版 | Harmony |
|------|---------|
| cbn.j 角标常渲染 + fq9.d 按钮 | `PageOverviewCell` Stack 常渲染 + onClick |
| ie case2 fill/outline 双图标 | `bookmark_tall_fill`/`bookmark_tall_outline` 按 `page.bookmarked` 切换 |
| cd_(un)bookmark_page_numbered | `accessibilityText($r(cd_…_numbered, pageIndex+1))` |
| wq2 普通态 → njg.b | `onToggleBookmark` → 面板 `onPageBookmark` → NotePage `dispatchPageContextAction(idx,'bookmark')` → `togglePageBookmarkAt`（de2.m/ae2 v0 日记化同一路径） |
| wq2 选择态 → pr2.D 选集 | `onToggleSelect`（既有 fd2 case0 等价） |
| f9n.b 编号 cd | checkbox `accessibilityText(cd_(de)select_page_numbered, pageIndex+1)` |
| bom icon cd ×3 | `SelectionActionChip` 新增 `cd?: ResourceStr` 参数，copy/duplicate/delete 三 chip 挂 `cd_*_pages` |
| or case18 清除钮 | `JumpToPageDialog` Stack(End) 尾部 `inputText.length>0` 时渲染灰圆+× 组合钮（ToolGlyph 无 evenOdd 填充规则 → 等价合成：textSecondary 圆 + control 色 ×），cd_clear_page_number，点击 `inputText=''` |
| close_search cd | 搜索钮 `accessibilityText(searchActive ? cd_pages_close_search : cd_pages_panel_search)` |

## 3. fail-closed / 差异记录

- `xmark_circle_fill` 的 evenOdd 镂空在 ArkUI Path 无 `fillRule` 等价
  （SDK 6.0.1(21) path.d.ts 无该属性）→ 采用圆底+前景色 × 合成，
  视觉等价但不支持镂空透明底层的极端底色场景（字段底色已知固定为
  control token，无实际偏差）。
- 原版 `bom` 的 more-actions 溢出钮与 `z7` 条件门（duplicate/delete
  渲染条件）：Harmony 工具条以文字 chip 呈现且 enabled 门控已覆盖
  同语义，未再引入图标钮形态（呈现层差异，行为等价）。
- `njg.b` 的确切方法名在 JADX 多路分发中不可静态判名（flag i=14
  多路调用），但其参数形状（pageKey 字符串 + 协程仓调）与书签切换
  写路径一致；Harmony 复用 `togglePageBookmarkAt`（已实现
  de2.m/ae2 v0 日记化 + undo 的同一 toggle）——写语义对齐，
  未新造存储路径。

## 4. 验证

- `node docs/migration/replays/d02-original-page-cells-a11y.mjs` → 56 checks OK
- 全量 Replay 基线：`REPLAY_BASELINE PASS=1260 FAIL=0 FILES=1260`
- `hvigorw assembleHap -p product=default -p module=note@default` → BUILD SUCCESSFUL
- `hvigorw clean && assembleHap -p module=note@ohosTest` → BUILD SUCCESSFUL
