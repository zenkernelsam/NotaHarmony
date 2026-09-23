# Phase 637 — 原版 Add Page 选中页后插入（u5j.i 锚点）

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-add-page-anchor-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0604-original-add-page-anchor.md`
- Replay：`docs/migration/replays/d04-original-add-page-anchor.mjs`（26 断言）

## 原版行为

菜单派发链（逐环已互证）：
`n9j.c` 菜单首项 `content_manager_add_page` → `c.function0` →
`n9j.g` `function3` → `id2` `new fd2(de2, pd2, 3)` → `fd2` case 3 →
`new zd2(de2, cxc, null, 0)`（zd2 协程变体 0；变体 1 = Rotate Page）。

`zd2` 变体 0（JADX debug 指令转储）：遍历 `a79.i` 定位选中页下标
`r12`，发射 `u5j.i(x09, r12 + 1, 0, 14)`。

`u5j.i`（u5j.java:667-677）：`bfj.b(pages, i, h)` 解析插入下标的
fractional 序列锚点，`haj.a(anchor, null, 1, oz9.UNBOOKMARKED, 16)`
产出 `ln2` 页描述符——**null nz9（继承笔记默认背景）+ 无书签 + 单页**。

结论：原版 Add Page = **选中页后插入**，非尾部追加。

## Harmony 实现

- `OriginalPagePersistence.ets`：`persistOriginalCreatePage(s)` 增加
  可选 `afterPageId`——非空时以 `readPageIdentity(afterPageId)` 为
  序列锚点（与 `persistOriginalDuplicatePage` 同型），缺省保留
  `readTailPosition`；新页仍 null nz9。
- `PageRepositoryImpl.ets`：`addPage`/`addPageInternal` 增
  `afterPageId` 参数。原版路径锚点后插入并断言落点 =
  `anchorIndex + 1`；legacy 路径无锚点时取
  `clamp(page.pageIndex, 0, before.length)`（导入顺序索引天然为尾位，
  redo 经 `action.pageAfter.pageIndex` 还原原位），`(note_id,
  page_index)` UNIQUE 索引下按倒序平移腾位。
- `RepositoryInterfaces.ets`：`PageRepository.addPage` 同步签名。
- `PersistentHistory.ets`：CREATE_PAGE 物化去掉"必须尾部"断言——
  只保留单插/空内容不变量；存量尾部 op 与新中部 op 均可回放。
- `NotePage.ets`：`addPage` 以 `insertIndex = currentPageIndex + 1`
  splice `pageOrderAfter` 与 `this.pages`，选中移至新页并同步修正
  移位页的内存 `pageIndex`；`applyAddPageHistory` 以
  `countString(pageOrderAfter, pageId) === 1` 取代尾部断言。

## 顺带修正

- `original-page-rotate-jadx-2026-09-23.md`：旧注"zd2 变体 0 =
  duplicate"系笔误，已更正为 Add Page（duplicate 实为 `fd2` case 7
  → `de2.r` → `ae2` 变体 5）。
- `d02-page-operation-disposal-bound.mjs`：钉住的尾部选中表达式
  `updated.length - 1` 更新为 `insertIndex`。

## 登记的后续差异（不在本 Phase）

- `de2.i` 删除补偿：删到剩余 <2 页时于 `size-1` 处自动补一张空页；
  Harmony 目前以 `pages.length <= 1` 直接阻塞末页删除。
- 原版 Paste 菜单插入锚点为 `de2.j`（最后选中页后，缺省末页），
  Phase 636 已实现同语义。

## 验证

- `d04-original-add-page-anchor.mjs`：**26/26**。
- 全量 Desktop Replay：**523/523 PASS**。
- `note@ohosTest` / `note@default` HAP：静态构建成功（无新增 ArkTS 错误）。
- 未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
