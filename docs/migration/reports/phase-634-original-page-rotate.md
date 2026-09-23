# Phase 634 报告：原版页面旋转（Rotate Page）页级 ModifyPage 移植

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-page-rotate-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0601-original-page-rotate.md`
- 性质：功能补齐（原版页级背景寄存器写路径首次接通）

## 背景

原版内容管理器页菜单的 Rotate Page 项
（`feature_note__content_manager_rotate_page`）在 Harmony 页管理条
菜单中缺席。审计需先裁决其作用域：nz9.rotation 字段既可出现在
页级 `ModifyPage`（ge8.field2 → m2d），也可出现在笔记级
`SET_METADATA`（l2d.field1 → m2d）与 `CreatePage`（wq9.field1）中。

## 证据链

- 派发链：`n9j.c` 菜单项 → `fd2(de2, pd2, 8)` → `zd2` 协程变体 1。
  `zd2.invokeSuspend` 结构化反编译失败，经
  `jadx --single-class --comments-level debug` 指令转储确认：
  `m18.O(nz9, null, Float(rotation), null, 27)` 只换 rotation；
  `u5j.s(x09, [pageId], null, m2d, null, 10)` → `r0j.a` 组装 ge8。
- 轮换：`cl4.a = π`（`ra` case 29），步进 0→π/2→π→3π/2→0，
  非基数角回落 0（eps 1e-4，`cl4.a`/`ddg.g` 互证）。
- PDF：`l7j.c(sw9, wz9.p(), wz9.F())` 重建为单页消费
  （pagesConsumed=1, pageOffset=pageInAsset, cropBoxes 单保留）；
  `wz9.p() = pageInAsset - pageOffset`（cropBoxes 下标）。
- 作用域结论：rotate 写**页级**寄存器，元素不变换；渲染由
  `wz9.j`（90°/270° 交换宽高）承担。

## 变更

- `OriginalSetMetadataPayloadEncoder.ets`：导出
  `encodeOriginalPageBackgroundTableBlob`（可重定位 nz9 blob）。
- `OriginalModifyPagePayloadEncoder.ets`：新增
  `encodeOriginalModifyPageBackground`（ge8 `[4,0,12,0]` +
  m2d setter field0→nz9）。
- `OriginalPagePersistence.ets`：新增 `persistOriginalPageBackground`。
- `PageRepositoryImpl.updatePage`：original-aligned 页路由至
  ModifyPage 背景写 + UPDATE_PAGE 历史伴随 op（替代原抛错路径）。
- `PageBackgroundModel.ets`：`nextOriginalPageRotation` +
  `rotatedOriginalPageInfo`（含 `l7j.c` 等价的 PDF 重建与
  解码器同公式的物化维度）。
- `PageManagerBar.ets`：页菜单新增 Rotate Page（bookmark 与
  clear 之间）+ `onRotatePage` 回调；`NotePage.rotateCurrentPage`
  接入 `runPageOperation` + PAGE_SETTINGS 撤销通道。
- 字符串：base/zh_CN `rotate_page`（Rotate Page / 旋转页面）。

## 验证

- 专项回放 `d04-original-page-rotate.mjs`：47/47 全绿。
- 全量回放 520/520 全绿（两个覆盖面 fixture 同步更新：
  `d02-local-set-metadata-background-outbound` 的旧抛错断言改为
  钉死 ModifyPage 路由；`d02-page-bar-shared-lease-bound` 的
  busy/lease 守卫计数 11→12）。
- `note@ohosTest` 与 `note@default` 双 clean 构建 0 错误
  （仅既有 ArkTS 警告）。

## 剩余边界

- 页菜单尚缺原版 add/cut/copy/paste/duplicate/create_template 等项，
  属于内容管理器整体范围，不在本 Phase 内。
- 旋转仅作用于背景/页面几何，元素不做坐标变换——与原版一致
  （原版同样只写 nz9）。
