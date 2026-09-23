# Phase 635 报告：原版页面复制（Duplicate Page）移植

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-page-duplicate-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0602-original-page-duplicate.md`
- 性质：功能补齐（原版页级复制路径首次接通）+ 新历史操作类型

## 背景

原版内容管理器页菜单的 Duplicate 项
（`feature_note__content_manager_duplicate`）在 Harmony 页管理条
菜单中缺席。同菜单的 `create_template` 经核实为
`lc4.a(ac4.w0)` INTERNAL_USERS_ONLY 门控——生产 1.0.3 不可见，
Harmony 不挂即 parity，本 Phase 仅落地 Duplicate。

## 证据链

- 派发：`n9j` 菜单项 → `de2.r(List)` → `ae2` 协程变体 5
  （de2.java:223-230；空选区仅日志返回）。
- `ae2` 变体 5：`de2.k` 取 (m1d, x09) → `u5j.e` 页序列化 →
  `de2.j` 锚点 → `m1d.c0` 转码应用。
- 页负载 `wz9.u`：有效 nz9（`B()` register ?? note 兜底）；PDF 页
  `l7j.c(sw9, cropIndex, pageInAsset)` 折叠单页消费后经
  `m18.O(nz9, sw9VarC, null, null, 29)` 只替换 pdf 字段；
  `haj.a(null, nz9, 1, (oz9) this.f.K, 16)` 携带 bookmark
  （ln2 field 3）与页身份 `this.i`。
- 锚点 `de2.j`：逆序遍历文档页表取最后一个选中页 → 副本紧随源页。
- 转码：`m1d.c0` 为流内实体重发全新操作身份（同剪贴板 `mappedIds`
  语义）。

## 变更

- `OpTypes.ets`：`OpType.DUPLICATE_PAGE = 4`（枚举空位，持久值不动）。
- `DuplicatePageOpCodec.ets`（新）：NDP1 伴随 codec——
  fromRevision/toRevision/sourcePageId/pageId/前后页序，
  验证器钉死单页插入 + 紧随源页。
- `PageBackgroundModel.ets`：`collapsedOriginalPagePdf` 抽出共享
  （rotate 同步改用）；`duplicatedOriginalPageBackground`。
- `OriginalCreatePagePayloadEncoder.ets`：全 nz9 背景参数 +
  `bookmarked`（ln2 field 3）。
- `OriginalPagePersistence.ets`：`persistOriginalDuplicatePage`
  （源页锚点 CreatePage + 有效背景 + 书签透传）。
- `PageRepositoryImpl.ets`：`duplicatePage`（事务内 CreatePage +
  DUPLICATE_PAGE 伴随 op + 紧随源页校验）、
  `restoreDuplicatedPage`（REDO 可见性恢复）；
  `RepositoryInterfaces` 同步声明。
- `StrokePersistence.ets`：抽出 `transcodeOriginalPageElements`，
  新增 `commitOriginalDuplicatePageContent`（空组图合法、目标页
  必须为空、内容 op 不带历史元数据）。
- `StrokeClipboard.ets`：`originalGroupGraphForPageCopy`——
  页内组集不动点收敛 + 页内根复制（修复笔记级 selectionGroups
  异页组误伤）。
- `UndoRedoManager.ets`：`DUPLICATE_PAGE` 动作类型 +
  `DuplicatePageAction` + 内存计量 + `commitDuplicatePageContent`
  桥接签名。
- `PersistentHistory.ets`：DUPLICATE_PAGE 物化（恰好一条伴随 op）。
- `NoteCanvasView.ets`：桥接实现（快照陈旧校验 + 页组图构建 +
  DUPLICATE_PAGE 路由进页历史通道）。
- `NotePage.ets`：`duplicateCurrentPage`（flush→快照→建页→
  内容→选中→push）、`applyDuplicatePageHistory`（undo 隐藏/
  redo 恢复）、校验分支。
- `PageManagerBar.ets`：Duplicate 菜单项（Bookmark 与 Rotate 之间，
  原版位序）+ `onDuplicatePage`；base/zh_CN `duplicate_page`
  （Duplicate / 复制页面）。

## 验证

- 专项回放 `d04-original-page-duplicate.mjs`：82/82 全绿。
- 全量回放 521/521 全绿（同步更新：
  `d02-page-bar-shared-lease-bound` 守卫计数 12→13；
  `d04-original-page-rotate` 钉 `collapsedOriginalPagePdf` 共享形态）。
- `note@default` assembleHap 0 错误（clean 双目标构建见末节）。

## 剩余边界

- 多选页批量复制（`de2.r` 接受 List）不在本 Phase——Harmony UI
  单页上下文，单页语义已完全对齐。
- `create_template` 生产不可见（INTERNAL_USERS_ONLY），不挂即 parity。
