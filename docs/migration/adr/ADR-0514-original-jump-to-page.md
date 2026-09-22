# ADR-0514 — 原版跳转到页

状态：Accepted（Phase 542）

## 背景

原版页指示器 `feature_note__page_indicator`（"N / M"）经 Compose
`m18.K` clickable 修饰链包裹（`n8.java` case 20），点击经 `g89` lambda
置位打开 `jump_to_title` 对话框（`ke1.java`），含 `jump_to_page_label`
数字输入；Go（`feature_note__jump_to_go`）仅在 `svd.p0` 解析成功且
`1 <= n <= pageCount` 时启用（`n8.java` case 21）。Harmony 此前为纯文本
指示器，无跳转入口。

## 决策

1. 页指示器加 `onClick` → 打开 `JumpToPageDialog`（`CustomDialogController`，
   `autoCancel`）；`busy || photoImportLeaseActive` 时 fail-closed，
   与兄弟回调同款守卫。
2. 对话框：`jump_to_title` 标题 + `InputType.Number` 输入（初始值=当前页）
   + Cancel/Go；`svd.p0` 语义以 `parseInt`+整串比对复刻，Go `enabled`
   当且仅当 `1 <= n <= pageCount`。
3. `onJumpToPage(pageIndex)` 回调经 NotePage 既有的 page-guard 集
   （loading/busy/history/lease + 边界）后赋 `currentPageIndex`——
   与 prev/next 同一防线。
4. 字符串 `jump_to_*` 双语；取消复用既有 `cancel`。

## 验证

`d02-original-jump-to-page.mjs` 21/21（原版锚点：page_indicator +
`m18.K` clickable 链 + `svd.p0` 范围校验 + `jump_to_*` 资源；Harmony
锚点：守卫式 onClick + dialog + range gating）；全套 437/437；
`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
