# Phase 1432：ON_BACKGROUND 冲刷对等报告（实改阶段）

- 日期：2026-08-09
- 状态：完成（实改；Desktop Replay 16 项本 Phase 检查）
- 证据：`docs/migration/evidence/phase-1432-background-flush.md`
- 决策：`docs/migration/adr/ADR-1367-background-flush-parity.md`
- Replay：`docs/migration/replays/d02-original-background-flush.mjs`

## 原版结论

- `MainActivity.onPause`/`onDestroy`/`onSaveInstanceState`：仅传感器
  注销、Play 评审/更新清理、`showWhenLockedPolicy` Bundle 字段——
  **无显式落盘**。
- `g80`/`f80` 生命周期监听：`mua`（OTel 闸门）+ `y10`（ANR 看门狗）
  ——纯遥测。
- 原版安全性来自 `zhi.emit`→`tee.a0` 逐变更写穿 + 文本编辑态本身即
  文档模型字段：后台/进程回收最多丢最后一个未发射事件。

## Harmony 差距（修复前）

`NoteAbility.onBackground` 为 stub；而 `editingDraftText`（文本草稿，
`onDraftChange` 只写缓冲）、`editingTitle`（标题草稿）、
`LatestWriteQueue` 挂起写均为进程内缓冲——后台被系统回收即丢稿。

## 实现

- 新增 `note/src/main/ets/data/EditorLifecycleFlush.ets`：token 登记 +
  fire-and-forget 冲刷。
- `NotePage`：`aboutToAppear` 注册 `flushPendingEditsForBackground`；
  `aboutToDisappear` 注销。冲刷体 = `performLeaveEditor` 前半：
  `saveTitle`/`titleSaveQueue` → `historyBridge.flushCurrentPage()`
  （连带提交文本草稿）→ `flushToolState` → `recordingDeleteController.flush`。
- `NoteAbility.onBackground` → `flushEditorsForBackground()`。

### 有意排除（与原版等价）

不导航（`router.back`）、不停录音（原版 `RecordingForegroundService`
后台续录）、租约/leave 进行中跳过、math/imageCrop 草稿不入库。

## 验证

- Replay `d02-original-background-flush.mjs`：16/16。
- 全量基线 1283/1283；note@default / note@ohosTest `BUILD SUCCESSFUL`。
