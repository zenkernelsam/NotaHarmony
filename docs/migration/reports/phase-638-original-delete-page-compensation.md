# Phase 638 — 原版末页删除补偿（de2.i 同流补页）

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-delete-page-compensation-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0605-original-delete-page-compensation.md`
- Replay：`docs/migration/replays/d04-original-delete-page-compensation.mjs`（56 断言）

## 原版行为

`ae2` case 4（plain delete 协程）调用 `de2.i(de2Var, x09Var, list)`，
经 `x82.I(m1d, th7, dof, …)` 单事务应用；`ae2` case 3（Cut）在序列化
进 `mg2.b` 页剪贴板后复用同一 `de2.i`。

`de2.i`（de2.java:116-131）：

1. `th7VarS.add(u5j.l(x09Var, arrayList, list, 10))`——先写删页
   delete-entities op；
2. `if (list2.size() - list.size() < 2)`——删后不足两页时，追加
   `u5j.i(x09Var, list2.size() - 1, 0, 14)` 空白页 op；
3. `m18.E(th7VarS)` 封包——**删除 + 补偿是单个撤销单元**。

`u5j.i` 产出 `haj.a(anchor, null, 1, oz9.UNBOOKMARKED, 16)`：null nz9
（继承笔记默认背景）、无书签、单页。插入下标 `size-1` = 末页边界，
对单页删除逐情形验证：补偿页恰好落受害页槽位（`[A]→[comp]`、
`[A,B]` 删 A →`[comp,B]`、删 B →`[A,comp]`），笔记页数不变。

## Harmony 实现

- `OpTypes.ets`：`DELETE_PAGE_COMPENSATION = 5`——承载"同长度
  一对一换页"，CREATE/DELETE 均无法表达该形状。
- `DeletePageCompensationOpCodec.ets`（新文件，magic `DCP1`）：
  编码 fromRevision/toRevision/deletedPageId/insertedPage（PageInfo
  全字段）/pageOrderBefore/pageOrderAfter；校验器接受 PUSH/REDO 正向
  与 UNDO 反向序对，拒绝非同槽位换页、空 id、身份冲突、越界
  pageIndex、尾字节。
- `PageRepositoryImpl.ets`：
  - `deletePageWithCompensation`（PUSH）：checkpoint + 受害页移除 +
    补偿页补插 + 落点 fail-closed 校验 + companion 落账，单事务。
    原版路径 `persistOriginalPageVisibility` 隐藏 +
    `persistOriginalCreatePage(anchor = before[size-2])`；legacy 路径
    `physicalDeletePage`（`page_info` 删除 + FK CASCADE 清元素）+
    `insertPageInfoAt`（倒序平移避让 UNIQUE 索引）。
  - `undoDeletePageWithCompensation`（UNDO）：复原受害页（unhide 或
    `restoreCheckpointedPage` 回填 checkpoint）+ 移除补偿页。
  - `redoDeletePageWithCompensation`（REDO）：`verifyDeleteCheckpointState`
    复核受害页 + 再删 + 复原补偿页。
  - 抽出 `restoreCheckpointedPage`/`physicalDeletePage`/`insertPageInfoAt`/
    `newCompensationPage`/`appendDeletePageCompensationCompanion`
    私有助手，三条路径共用。
- `RepositoryInterfaces.ets`：`PageRepository` 增加三个方法声明。
- `PersistentHistory.ets`：`materializeAction` 新增
  `DELETE_PAGE_COMPENSATION` 分支——恰好一条 companion op，解码
  + `findDeleteCheckpoint` 取受害页快照，物化为带 `compensationPage`
  的 `DeletePageAction`；checkpoint `createdTime` 与 actionTime
  一致性校验保留。
- `UndoRedoManager.ets`：`DeletePageAction.compensationPage?: PageInfo`。
- `NotePage.ets`：
  - `deleteCurrentPage` 门由 `pages.length <= 1` 放宽为 `=== 0`；
  - `deleteCurrentPageLocked`：`orderBefore.length <= 2` 时走
    `deletePageWithCompensation`，补偿页 splice 回受害页槽位、
    回填 action 的 `compensationPage`/`pageOrderAfter`/
    `selectedPageIdAfter`，选中移至补偿页；
  - `applyDeletePageCompensationHistory`：undo 移除补偿页+按
    `pageOrderBefore` 复原受害页，redo 删受害页+按 `pageOrderAfter`
    补回补偿页；
  - `isDeleteCompensationTransition`：同长度序对中仅允许受害页槽位
    被补偿页一对一替换；
  - `validatePageActionState` DELETE_PAGE 分支按有无
    `compensationPage` 分流校验。
- `PageManagerBar.ets`：删除按钮与 `delete_page` 菜单项移除
  `pageCount > 1` 门（菜单项改用 fail-closed 形态）。

## 顺带修正

- `d02-page-delete-removal-lease-bound.mjs`、`d02-page-structure-lease-bound.mjs`：
  删除前置门断言由 `pages.length <= 1` 更新为 `=== 0`。
- `d02-page-manager-consistency-shared-ingress-lease-bound.mjs`：删除
  按钮 enabled 断言去 `pageCount > 1`；菜单项改 fail-closed 后单独断言。
- `d02-page-bar-shared-lease-bound.mjs`：fail-closed 门计数 16→17
  （删除菜单项迁入该形态）。
- `d02-page-operation-disposal-bound.mjs`：钉住的 `selectedAfter`
  表达式更新为补偿感知的双分支形式。

## 范围说明

Harmony 编辑器仅暴露单页删除入口；`de2.i` 的多页批量形态在 Harmony
无对应 UI（`tfh` 多选工具栏删除为登记差异）。Cut 复用
`deleteCurrentPage`，自动获得补偿——与原版 `ae2` case 3 复用
`de2.i` 同型。

## 验证

- `d04-original-delete-page-compensation.mjs`：**56/56**。
- 全量 Desktop Replay：**524/524 PASS**。
- `note@ohosTest` / `note@default` HAP：静态构建成功（无新增 ArkTS 错误）。
- 未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
