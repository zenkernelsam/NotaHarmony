# ADR-0404：NOTE_METADATA 历史的 note 状态门禁

## 状态

已接受（2026-08-25，Phase 432）。

## 背景

Phase 431 为 NOTE_TITLE 增加独立历史入口后，NOTE_METADATA 仍走通用页面历史入口。
虽然当前生产 UI 未主动创建该动作，但持久化层与撤销栈保留其恢复路径。若未来 note-level
SET_METADATA 恢复外部队列，通用入口无法感知 `pageOperationBusy` 或标题保存飞行状态，
可能在 note 状态变化期间放行并竞争持久化结果。

## 决策

1. NOTE_METADATA 使用独立 `onApplyNoteMetadataHistory()` 入口，非 note-level 动作继续走原入口。
2. 页面操作进行中或标题保存飞行中直接 fail closed；导航租约继续由既有成功/失败续体释放。
3. 不新增冗余状态字段，先复用现有权威 note-state 标志；后续引入独立 metadata 队列时，
   在同一入口扩展对应 in-flight 门禁。

## 后果

note-level 历史入口现在显式绑定共享 note 状态边界，避免依赖“当前无 caller”作为安全依据。
普通页面动作、元素动作和导航语义不变。
