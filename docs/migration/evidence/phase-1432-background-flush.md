# Phase 1432 — 原版 ON_BACKGROUND 冲刷对等

## 原版证据（decompiled_1.4.2）

### Activity 生命周期无显式落盘

`sources/com/gingerlabs/notability/app/MainActivity.java`：

- `onPause()`（行 ~589）：仅 `SensorManager.unregisterListener(d4g)`（加速
  度计，摇晃调试菜单用），随后 `super.onPause()`。**无任何笔记/数据库
  冲刷调用。**
- `onDestroy()`（行 ~518）：仅 `k().d(this.V)`（Play 应用内更新监听
  注销）、`nu6` 评审窗口 identityHashCode 清理、`mqg` S Pen quick-tools
  归属清理。**无持久化调用。**
- `onStop`/`onSaveInstanceState`：仅 `showWhenLockedPolicy` Bundle 字段。

### Process 生命周期监听 = 纯遥测

`fo3` 接口（onCreate/onStart/onResume/onPause/onStop/onDestroy）→
`g80`（`Closeable` 的 `f80` 监听表，经 `b40`/`v69` 挂到 Process lifecycle）。
`f80` 的全部实现：

| 实现 | onStart→a() | onStop→b() | 性质 |
|------|-------------|------------|------|
| `mua` | `AtomicBoolean.set(true)` | `set(false)` | OTel `lua` 任务派发前台闸门 |
| `y10` | `scheduleWithFixedDelay(b20, 1s)` | `cancel(true)` | ANR 看门狗（主线程栈采集上报 `io.opentelemetry.anr`） |

**结论：原版没有任何"退后台冲刷"生命周期钩子。**

### 原版为什么不需要：逐变更写穿

`zhi.emit`：每条文档状态发射即 `tee.a0(gii.y, …)` 在专用 scope 起协程
写库（`hrb`/`qei`/`xki` 三类状态流同样处理）。文本编辑态本身即文档模
型字段（Compose state → mutation flow），每一笔既改模型又触发保存管
线 → **进程被杀时最多丢"最后一个尚未发射的事件"，不存在成批未提交
草稿**。

### 录音后台行为

`feature/note/toolbox/audio/record/RecordingForegroundService.java` —
前台服务，退后台继续录音。故 ON_BACKGROUND **不得**停录音。

## Harmony 侧差距（修复前）

`NoteAbility.onBackground()` 是 stub（仅 hilog）。而 Harmony 编辑器存
在三类**进程内缓冲**的未持久态：

1. `NoteCanvasView.editingDraftText` — 文本草稿：`onDraftChange` 只写
   缓冲（+宽度预览量算），`textBlocks` 模型直到 `onTextCommit`
   （blur/离开/结束编辑）才更新。后台被杀 → 整段草稿丢失。
2. `editingTitle` 标题草稿 — `saveTitle()` 只在提交/blur/离开时落库。
3. `LatestWriteQueue` 挂起写 — `enqueue` 虽立即 `start()`，但 coalesce
   期间的 pending 项与飞行中写在进程被杀时都会丢。

三者分别对应 `performLeaveEditor()` 前半的 `saveTitle`/`titleSaveQueue`、
`historyBridge.flushCurrentPage()`（内部对 `editingTextBlock` 调
`onTextCommit(editingDraftText)` 再 `persistence.flush`）、
`viewModel.flushToolState()`/`recordingDeleteController.flush()`。

## Harmony 实现（本阶段新增）

- 新增 `note/src/main/ets/data/EditorLifecycleFlush.ets`：token 化
  回调登记（`registerBackgroundFlush`/`unregisterBackgroundFlush`/
  `flushEditorsForBackground`，fire-and-forget + hilog）。
- `NotePage.aboutToAppear` 注册 → `flushPendingEditsForBackground()`；
  `aboutToDisappear` 在 `editorDisposed=true` 后即刻注销。
- `flushPendingEditsForBackground()` = `performLeaveEditor` 前半：
  标题草稿 `saveTitle`/`titleSaveQueue` → `historyBridge.flushCurrentPage()`
  （连带提交文本草稿 + 冲刷页写队列）→ `flushToolState()` →
  `recordingDeleteController.flush()`。
- `NoteAbility.onBackground` → `flushEditorsForBackground()`。

## 有意排除（与原版等价）

- **不导航**：`router.back()` 仅 `performLeaveEditor` 末尾；后台不是
  离开页面。
- **不停录音**：`finishRecordingSession`/`recordingController.release`
  不做 —— 原版 `RecordingForegroundService` 后台续录。
- **租约门**：`photoImportLeaseActive`/`pageStructureLeaseActive` 活跃时
  跳过（与 performLeaveEditor 同规——导入/页结构事务进行中不冲刷）。
- **math/imageCrop 覆盖层**：`flushCurrentPage` 内建 fail-closed 返回
  false —— 草稿态本就不入库，与原版一致。
- **leave 进行中**（`editorLeavePromise !== null`）跳过——避免与导航
  冲刷竞争同一文本提交。

## 验证

- Replay `d02-original-background-flush.mjs`：15/15。
- 全量基线、note@default、note@ohosTest 见提交记录。
