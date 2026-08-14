# ADR-0188：原版录音捕获残留的启动期回收

## 状态

Accepted，2026-08-14。

## 问题

Harmony 录音后端把尚未发布的捕获结果直接写入应用 `context.tempDir`：

- 麦克风：`recording_<time>_<sequence>.m4a`
- 设备内录：`internal_recording_<time>_<sequence>.m4a`

正常 `stop` 后，文件会交给 `OriginalRecordingPersistence` 发布到规范资产目录并在 `finally` 中删除；启动失败、
停止失败和显式 `abort` 也会由各后端回收输出。然而进程在录制、停止或持久化前被系统杀死时，任何进程内
`finally` 都无法执行。`tempDir` 不属于系统 Backup 快照，也没有别的持久消费者，因此这些文件只会成为永久
残留并持续占用应用空间。

Phase 210 已回收 `filesDir/assets/pending` 与 `assets/trash`，但它没有覆盖录音后端自己的原始捕获目录；两类
文件的生产者和生命周期不同，不能把 `tempDir` 作为资产目录递归清空。

## 原版证据

- `decompiled_1.0.3/sources/defpackage/gv2.java` case 13：录音拥有者启动时枚举
  `temp_recordings`、`AudioCaptures` 的直接子项并删除上次运行遗留文件。
- `decompiled_1.0.3/sources/defpackage/tr8.java`：普通录音在 `filesDir/temp_recordings` 创建
  `recording_<date>` 输出。
- `decompiled_1.0.3/sources/com/gingerlabs/notability/feature/note/toolbox/audio/record/wrapper/audio/AudioCaptureService.java`：
  捕获服务在 `filesDir/AudioCaptures` 创建 `Recording-<date>.pcm`。

这些实现证明原版把未完成录音视为仅属于当前捕获会话的临时工件，并在拥有者下次启动时回收。Harmony
无需照搬 Android 目录或 PCM 转码结构，但应保留相同的所有权与崩溃恢复语义。

## 决策

1. 新增 `cleanupInterruptedOriginalRecordingCaptures(tempRoot)`，在第一次
   `DatabaseManager.openAndMigrate()` 发布 `RdbStore` 前对 `context.tempDir` 执行一次回收。
2. 编辑器只有在 `loadPages()` 等待数据库初始化成功并获得页面后才会显示可操作的录音面板；初始化完成后
   `DatabaseManager.initialize()` 直接复用已打开 store，不会在正常运行中重新扫描。因此该边界位于本进程
   任何可启动捕获之前，不会删除当前会话的活动输出。
3. 只枚举 `tempDir` 的直接子项，不递归进入任何目录，也不执行目录删除。
4. 只接受 Harmony 当前两个生产者可以生成的严格名称：
   `recording_<digits>_<digits>.m4a` 与 `internal_recording_<digits>_<digits>.m4a`。
5. `listFileSync()` 返回项必须重新证明为目标目录的直接子项；未知名称、嵌套路径、目录穿越、目录外路径与
   名称伪装目录全部保留。只有普通文件才允许 `unlinkSync()`。
6. 单文件失败只累计并记录，继续处理其他项；目录不存在视为正常。根路径为空、根不是目录、枚举失败或
   单项删除失败均不阻断数据库启动，后续进程启动仍可重试。
7. 不改变两个 capture backend 的 stop/abort 清理，也不改变 `OriginalRecordingPersistence` 的发布后删除；
   启动回收只兜底处理进程死亡后无法由正常控制流消费的孤儿。
8. 系统 Backup 继续只包含 `filesDir` 与 `databaseDir`，不把 `tempDir` 残留带入恢复快照。

## 结果

- 录音中途杀进程不再永久积累麦克风或设备内录 `.m4a`。
- 临时目录中的导出文件、平台文件、未来未知命名、嵌套目录和目录外目标不会被宽泛清理误删。
- 原版“录音拥有者启动时回收上一会话捕获”的行为在 Harmony 上恢复，同时保留现有 AVRecorder、native
  screen capture 与规范资产发布实现。
- 单个不可删除文件不会让整个笔记数据库失效，并保留精确统计用于设备诊断。

## 边界

- 桌面 replay 证明命名、路径、顺序与幂等契约；真实杀进程、权限错误、磁盘故障和 AVRecorder/native
  文件句柄行为仍需设备故障注入。
- 只清理当前已证实的 Harmony 命名，不猜测未来版本或旧实验版本的文件名。
- 该决策不清理 `tempDir` 中的 `.note` 导出文件或其他子系统临时工件；它们必须由各自生产者证据和独立
  生命周期协议处理。
