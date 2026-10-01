# ADR-1367：ON_BACKGROUND 冲刷对等（文本/标题草稿 + 挂起写落库）

- 状态：Accepted
- 关联：ADR-0681（MainActivity 生命周期尾审）、ADR-0645（iink 边
  界）、evidence `phase-1432-background-flush.md`、fixture
  `d02-original-background-flush.mjs`

## 背景

`onPause`/`onStop`/`onDestroy` 生命周期持久化语义审计。

## 原版裁决

- `MainActivity.onPause` 仅注销加速度计（摇晃菜单）；`onDestroy` 仅
  `nu6`（评审窗口）/`mqg`（S Pen quick-tools）/`k().d`（Play 更新监
  听）清理；`onSaveInstanceState` 只写 `showWhenLockedPolicy`。
- `g80`/`f80` 监听表的全部实现是 `mua`（OTel 派发前台闸门）与
  `y10`（ANR 看门狗 `b20`，1s 轮询主线程栈）——纯遥测，无持久化。
- 原版**没有**"退后台冲刷"钩子；其安全性来自 `zhi.emit`→`tee.a0`
  逐变更写穿 + 文本编辑态本身即文档模型字段。

## Harmony 差距与决定

Harmony 的写路径是 `LatestWriteQueue`（enqueue 立即 start，pending
仅在写飞行中 coalesce）+ 两类**纯内存草稿**
（`editingDraftText`/`editingTitle`——直到 `onTextCommit`/`saveTitle`
才进模型）。`onBackground` 原为 stub：应用退后台被系统回收即丢草
稿——相对原版是真差距（原版后台不存在成批未提交态）。

**决定**：新增 `EditorLifecycleFlush` 登记 + `NoteAbility.onBackground`
尽力冲刷 = `performLeaveEditor` 前半（`saveTitle`/`titleSaveQueue` →
`historyBridge.flushCurrentPage()` → `flushToolState` →
`recordingDeleteController.flush`）。

### 有意排除（fail-closed 等价，非缺漏）

- 不 `router.back()`：后台非离开页面。
- 不 `finishRecordingSession`/`recordingController.release`：原版
  `RecordingForegroundService` 前台服务使录音后台续录。
- `photoImportLeaseActive`/`pageStructureLeaseActive`/`editorLeavePromise`
  活跃时跳过（与 performLeaveEditor 同门，避免竞争）。
- math/imageCrop 覆盖层：`flushCurrentPage` fail-closed 返回 false，
  草稿态不入库与原版一致。

## 验证

- `d02-original-background-flush.mjs` 15/15；全量基线 1283/1283；
  note@default / note@ohosTest 构建成功。
