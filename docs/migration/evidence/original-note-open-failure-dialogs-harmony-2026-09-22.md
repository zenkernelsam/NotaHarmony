# Phase 543 — 原版笔记打开失败对话框（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/editor/NotePage.ets`、双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

`u49.java` 笔记屏幕按 `vc9` 密封类失败态渲染终态对话框
`u49.a(dismiss, titleRes, messageRes, buttonRes)`（内部 `f2j.c`
AlertDialog）：

| 状态类 | 资源前缀 | 标题 / 按钮文案 |
|---|---|---|
| `rc9` | `load_failed_*` | "Unable to open note" / OK |
| `qc9` | `download_failed_*`（button 复用 load_failed_button） | "Unable to download note" / OK |
| `pc9` | `access_denied_*` | "Permission required" / Done |
| `uc9` | `note_deleted_*` | "Note unavailable" / Done |

`u49.a:25-51`：按钮与外部点击经 `u8(function0, gl8Var, 20)` 共享同一
dismiss 回调——确认与外侧取消都触发 `function0`（返回上一页），且
`gl8Var` 记录已关闭态防止重复。

## Harmony 落地

`NotePage`：

- `@State pageLoadFailureKind`：'' | 'deleted' | 'failed'。
- `getNote` 返回 `null` 或 `note.deletedAt !== null` → kind='deleted'
  （uc9 等价：Recently Deleted 页面不提供打开入口，打开已删笔记只可能
  来自过期路由——与原版"unavailable"语义一致）；其余加载异常 →
  kind='failed'。
- catch 统一打开 `NoteFailureDialog`（@CustomDialog）：标题/消息/按钮
  随 kind 切换——"Note unavailable"/"The note you are trying to access
  is unavailable at this time."/Done 或 "Unable to open note"/
  "This note could not be loaded. Please try again later."/OK。
- `dismissLoadFailure`：按钮与 `autoCancel` 的 `cancel` 回调共用
  `failureDismissHandled` 幂等守卫后 `router.back()`——复刻 `u8`
  共享回调 + 单次语义。
- 移除原 Harmony 自造的内联 Retry 按钮与 toast：原版该表面无重试
  入口，失败即终态返回。`pageLoadFailed` 保留作各守卫条件，背景列仅
  显示对应失败标题（scaffold 衬底）。

## 差异登记

- `qc9` download_failed / `pc9` access_denied：Harmony 无云端存根笔记
  与共享权限模型，无可移植触发路径——登记。
- 打开后被删除（打开态被外部删除）的 uc9 触发需要 note_meta 变更
  观察者——当前仅覆盖打开时刻，登记。
- ArkUI CustomDialog 替代 Compose `f2j.c` AlertDialog；`autoCancel`
  + `cancel` 复刻外侧取消共享回调。
