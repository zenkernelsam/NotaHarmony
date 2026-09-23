# ADR-0605：原版末页删除补偿（de2.i 同流补页）

- 状态：Accepted
- 日期：2026-09-23
- 阶段：Phase 638
- 证据：`docs/migration/evidence/original-delete-page-compensation-jadx-2026-09-23.md`

## 背景

原版 `de2.i` 构造的删页 op 流在 `list2.size() - list.size() < 2`（删后
不足两页）时追加 `u5j.i(x09, list2.size() - 1, 0, 14)`——删除与补页
在同一 `th7` 流中封包，构成**单个撤销单元**；补偿页为 null nz9、
UNBOOKMARKED 的空白页，落在受害页槽位。Harmony 此前以
`pages.length <= 1` 直接阻塞末页删除，并在 `PageManagerBar` 以
`pageCount > 1` 禁用删除入口——与原版"笔记永不为零页、删除永不
因页数禁用"的语义不符。

`classifyPageStructureMutation` 只能表达"成员 ±1"的页结构变更
（CREATE/DELETE），而补偿删除是**同长度的一对一换页**（受害页出、
补偿页入）——两个既有 op 类型都无法承载，若拆成 DELETE_PAGE +
CREATE_PAGE 两个 op 又会被物化成两个独立动作，破坏原版的单撤销
单元语义。

## 决策

1. **专用 companion op**：新增 `OpType.DELETE_PAGE_COMPENSATION = 5`
   与 `DeletePageCompensationOpCodec`（magic `DCP1`）。载荷携带
   `deletedPageId`、`insertedPage`（PageInfo 全字段：尺寸/模板/方向/
   宽高/背景/`originalPageInAsset`/书签）、`pageOrderBefore/After`；
   校验器接受正向（PUSH/REDO：受害页→补偿页）与反向（UNDO：补偿页
   →受害页）两种序对，并要求换页发生在同一槽位
   （`expected = source.map(victim→blank) === target`）。
2. **单事务仓储 API**：`deletePageWithCompensation` 在一次事务中完成
   checkpoint（受害页 PageInfo + 元素 + 检索行）→ 移除受害页 → 补插
   空白页 → 落点校验 → 追加 companion；任一步失败整体回滚。
   - 原版路径：`persistOriginalPageVisibility(victim, true)` 隐藏 +
     `persistOriginalCreatePage(anchor = before[size-2])`——锚定为
     倒数第二页，使补偿页在三种页数/槽位组合下都恰好落受害页槽位
     （与 `de2.i` 的 `size-1` 边界语义等价）。
   - legacy 路径：`physicalDeletePage`（`page_info` 行删除 +
     FK CASCADE 清理元素/检索行）+ `insertPageInfoAt`（倒序平移
     避让 `(note_id, page_index)` UNIQUE 索引）；补偿页借受害页尺寸，
     `background = null`（读时解析为笔记默认背景）、`bookmarked =
     false`。
3. **撤销/重做镜像**：`undoDeletePageWithCompensation` 复原受害页
   （原版路径 unhide；legacy 路径 `restoreCheckpointedPage` 回填
   checkpoint）并移除补偿页；`redoDeletePageWithCompensation` 反向。
   两者各自追加同型 companion（UNDO/REDO effect），payload 中的
   序对与移动方向一致——持久层移动记录只驱动栈迁移，物化始终只读
   PUSH op。
4. **UI 单动作**：`DeletePageAction.compensationPage` 可选字段；
   `deleteCurrentPageLocked` 在 `orderBefore.length <= 2` 时走补偿
   分支（action 的 `pageOrderAfter`/`selectedPageIdAfter` 在仓储返回
   补偿页身份后回填）；`applyDeletePageCompensationHistory` 与
   `isDeleteCompensationTransition` 完成同槽位换页的校验与应用；
   `PageManagerBar` 删除按钮与菜单项移除 `pageCount > 1` 门。
5. **范围限定**：Harmony 编辑器仅暴露单页删除入口；
   `de2.i` 的多页批量删除形态（`list.size() > 1`）在 Harmony 无对应
   UI，本 Phase 只对单页删除路径对齐。Cut（Phase 636）经
   `deleteCurrentPage` 复用，自动获得补偿。

## 后果

- 末页/次末页删除不再阻塞：1 页笔记删页 → 补一张空白页；2 页笔记
  删页 → 幸存页 + 受害页槽位的空白页。
- 删除 + 补偿是一个撤销单元：撤销恢复受害页内容并撤去空白页，重做
  重放组合——与原版 op 流语义一致。
- `DELETE_PAGE` 既有 op 与 checkpoint 表结构不变；新 companion 仅
  在补偿删除时写入，存量历史回放不受影响。
- 已登记的相邻差异不变：多页批量删除入口（`tfh` 多选工具栏）在
  Harmony 尚无对应 UI，如需对齐另行立项。
