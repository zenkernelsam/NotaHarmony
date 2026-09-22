# ADR-0515 — 原版笔记打开失败对话框

状态：Accepted（Phase 543）

## 背景

原版笔记屏幕按 `vc9` 失败态经 `u49.a` 渲染终态 AlertDialog：
rc9 load_failed（"Unable to open note"/OK）、qc9 download_failed、
pc9 access_denied、uc9 note_deleted（"Note unavailable"/Done）；
按钮与外侧取消经 `u8` 共享同一 dismiss 回调（返回上一页）。Harmony
此前仅显示内联错误文本 + 自造 Retry 按钮 + toast。

## 决策

1. `pageLoadFailureKind` 区分 'deleted'（`getNote` 为 null 或
   `deletedAt != null`）与 'failed'（其余加载异常）；catch 统一打开
   `NoteFailureDialog`。
2. 对话框文案逐项对齐原版字符串；按钮 Done/OK 与 `autoCancel` 的
   `cancel` 回调经 `failureDismissHandled` 幂等后 `router.back()`。
3. 移除内联 Retry 与 toast——原版该表面无重试入口，失败即终态；
   `pageLoadFailed` 保留供既有守卫使用，背景列显示失败标题衬底。
4. download_failed / access_denied / 打开后被删除：无可移植触发
   路径——登记。

## 验证

`d02-original-note-open-failure-dialogs.mjs` 31/31；
`d02-editor-initialization-disposal-bound` 两锚点合法演进（toast→
dialog、retry→terminal dismiss）；全套 438/438；`note@default` +
`note@ohosTest` BUILD SUCCESSFUL。
