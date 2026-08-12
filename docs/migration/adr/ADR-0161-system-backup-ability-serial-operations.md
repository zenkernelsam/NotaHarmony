# ADR-0161：系统 Backup Ability 串行化操作

## 决策

同一个 `NoteBackupAbility` 实例中的 backup/restore 请求通过 promise 队列严格串行执行；
失败不会阻断后续请求，后续操作仍会在前一操作 settled 后开始。

## 原因

backup 与 restore 共用 snapshot、previous、staging 和 rollback 路径。并发执行会产生
交叉 rename/copy，导致 manifest、进度状态和文件内容不一致。

## 边界

进程被系统终止后的跨实例恢复仍需 CoreFileKit 设备验收；本 ADR 只保证单 Ability 实例
内的调用顺序。
