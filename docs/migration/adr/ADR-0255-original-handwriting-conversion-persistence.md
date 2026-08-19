# ADR-0255：原版手写 Convert-to-Text 的原子持久化与历史

## 状态

Accepted - Phase 277（2026-08-19）

## 背景

Phase 276 已固定单页、8-unit bounds、page-relative origin、迟到 OCR 门禁和
`DELETE_ENTITIES → CREATE_BLOCK(TEXT) → INSERT_STRING` 顺序，但当时没有能把三类 original
operation、页面快照和 durable Undo/Redo 放进一个一致事务的 production path。

三个 reducer 若各自推进 page revision，会让一个原版 transaction 在 Harmony 变成三次页面变化；若走 generic
snapshot fallback，又会漏掉 original visibility winner、Block/Text CRDT state 和 uploadable operation identity。
任何中途失败都可能造成 Ink 已删除而 Text 不完整。

## 决策

### 1. 增加专用 persistence API

新增 `StrokePersistence.commitOriginalHandwritingConversion()`，只接受已通过 Phase 276 planner 与 OCR
迟到门禁的不可变 source Ink 快照、page-relative origin、size、recognized text 和非合并 PUSH history。
该 API 先 flush 同页普通保存队列，再在 `editorPersistenceMutex` 与一个 RDB transaction 中完成全部工作。

### 2. 严格保持原版三步 operation

依次分配并 append 三条可上传 original operation：

```text
type 25 DELETE_ENTITIES(source Ink)
type 22 CREATE_BLOCK(TEXT)
type 8  INSERT_STRING(created Text, recognized text)
```

三条 operation 各有自己的原版 identity；不会把它们折叠成 Harmony snapshot，也不会制造不存在的原版
“Convert-to-Text” wire type。

### 3. 三个 reducer 共用一个 revision batch

`OriginalDeleteEntitiesOperationApplier` 增加不支持 page visibility 的 batched entity 路径；DELETE、CREATE、
INSERT 共用一个 `OriginalPageMutationBatch`，末尾只 `flush()` 一次。batch 合并 Ink/Text search invalidation，
页面 revision 只增加 1。

### 4. source stale 与 wire 数值 fail closed

每条 source Ink 必须是 finished、非 highlighter、非 partial eraser 的 canonical original identity。调用参数先经
persistence codec clone，transaction 内再与当前 snapshot payload 逐字节比较，并确认 original entity state 存在。

origin、size 与派生 bounds 必须可安全 round-trip 为有限 Float32；recognized text 复用生产
`encodeOriginalInitialInsertString()` 的 UTF-8/1 MiB 限制。任何失败整体 rollback。

### 5. HWC1 作为 Harmony durable history companion

新增 `OpType.ORIGINAL_HANDWRITING_CONVERSION=36`、runtime action type 24 和 HWC1 codec。HWC1 保存完整
page mutation、source Ink IDs、Text ID；decoder 校验外层字段与内嵌 persisted payload 的 kind/ID。

Undo/Redo 各只生成一条 type-25 visibility operation：Undo 隐藏 Text/恢复 Ink，Redo 隐藏 Ink/恢复 Text。
移动前后均校验完整页面快照与单次 revision；HWC1 UNDO/REDO row 和 visibility mutation 同事务提交。

### 6. 本阶段不开放产品入口

专用 persistence API 暂无 UI caller。真实 provider、Locale/global preference adapter、SelectionOverlay 入口、
生产 page/frame/fingerprint 采集与用户错误提示仍缺失，不因底层闭环而提前开放菜单。

## 后果

正面：

- 原版三步顺序和 operation identity 被真实持久化，不再依赖 generic snapshot 猜测；
- 一个转换只推进一次 page revision，同时失效 Ink/Text 两类搜索索引；
- stale OCR、Float32 溢出、超大 UTF-8、任一 reducer/history 失败均不会留下半成品；
- 重启后可从 HWC1 恢复 dedicated Undo/Redo action。

代价与边界：

- HWC1 是 Harmony 本地 history companion，不上传，也不是原版 wire schema；
- 目前没有产品调用者，不能把基础设施完成写成“功能上线”；
- 设备端 OCR 质量、性能、交互与 round-trip 仍需后续阶段验证。

## 验证

- 原版 hash/行号与对应关系见
  `docs/migration/evidence/original-handwriting-conversion-persistence-jadx-2026-08-19.md`；
- ArkTS fixtures 覆盖 HWC1 round-trip/corruption、内嵌 payload 绑定、stale replay、history PUSH/UNDO/REDO、
  Float32/UTF-8/source 门禁与 mixed batch 单 revision；
- 专项 Replay 静态验证原版顺序、共享 batch、单次 flush、visibility Undo/Redo、codec/history 与 fixture 注册；
- 全量 Replay、`git diff --check`、严格串行 clean/双 HAP 必须通过；不启动设备或 Hypium。
