# ADR-0604：原版 Add Page 选中页后插入（u5j.i 锚点）

- 状态：Accepted
- 日期：2026-09-23
- 阶段：Phase 637
- 证据：`docs/migration/evidence/original-add-page-anchor-jadx-2026-09-23.md`

## 背景

原版内容管理器菜单首项 Add Page（`n9j.c` function0 → `g.function3` →
`fd2` case 3 → `zd2` 变体 0）对选中页下标 `r12` 发射
`u5j.i(x09, r12 + 1, 0, 14)`——`haj.a(bfj.b(pages, i, h), null, 1,
oz9.UNBOOKMARKED, 16)`：新页紧随选中页，nz9 = null 继承笔记默认背景，
无书签。

Harmony 此前 `addPage` 一律尾部追加（`readTailPosition` +
`orderBefore.concat`），并把该假设写进了两处：持久层
`PersistentHistory` 的 CREATE_PAGE 物化断言"added page 必须在尾部"，
与 `applyAddPageHistory` 的 `pageOrderAfter[last] === pageId` 守卫。
两者都是政策断言而非格式约束——`classifyPageStructureMutation` 对
任意单点插入即分类 CREATE_PAGE，`isSinglePageTransition` 本身位置无关。

## 决策

1. **原版路径锚点化**：`persistOriginalCreatePage(s)` 增加可选
   `afterPageId`——非空时以 `readPageIdentity(afterPageId)` 为序列
   锚点（与 `persistOriginalDuplicatePage` 同型），缺省保留
   `readTailPosition`。新页仍发 `requestedPage = null`（null nz9 =
   继承笔记默认背景），与 `haj.a(anchor, null, …)` 同型。
2. **legacy 路径按 page_index 腾位**：无锚点时取
   `clamp(page.pageIndex, 0, before.length)`（导入顺序索引天然等于
   尾位，redo 经 `action.pageAfter.pageIndex` 还原原位）；有锚点时取
   `anchorIndex + 1`。因 `(note_id, page_index)` 有 UNIQUE 索引，
   平移按**倒序**执行避免事务内碰撞。
3. **历史断言去尾化**：`PersistentHistory` 物化只保留单插/空内容
   不变量；`applyAddPageHistory` 以
   `countString(pageOrderAfter, pageId) === 1` 取代尾部断言。
   存量尾部 op 仍合法，新增中部插入 op 亦可回放。
4. **redo 语义不变**：原版路径下 undo = 隐藏页、redo =
   `persistOriginalPageVisibility` 复原——页身份保留原位，天然
   位置无关；legacy 路径 redo 由 `page.pageIndex` 落位。
5. **UI 落点**：`NotePage.addPage` 以 `insertIndex =
   currentPageIndex + 1` splice `pageOrderAfter` 与 `this.pages`，
   选中项移至新页（与原版一致），并同步修正移位页的内存 pageIndex。

## 后果

- Add Page 行为与原版一致：当前页后插入；在末页时退化为尾部追加。
- 既有尾部假设被打破后，`ADD_PAGE` 历史可在任意位置回放——
  `DUPLICATE_PAGE`/`insertCopiedPage` 中部插入已验证同型机制可行。
- 登记后续差异（不在本 Phase）：`de2.i` 删除补偿（删到 <2 页时于
  `size-1` 处自动补页）与 Harmony `pages.length <= 1` 阻塞末页删除
  的行为分歧。
