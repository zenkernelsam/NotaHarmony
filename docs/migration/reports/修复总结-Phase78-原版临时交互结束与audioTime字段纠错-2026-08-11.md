# Phase 78 修复总结：原版临时交互结束与 audioTime 字段纠错

日期：2026-08-11

## 问题

原版 payload type 26 `TRANSIENT_INTERACTION_ENDED` 会被 Harmony 统一路由视为不支持的 transient
操作，进入 durable inbox 后永久 deferred，并阻塞同一笔记后续队头。更严重的是，既有代码把原版
`uq9` root field 3 当成 transient 布尔值；直读原版生成代码后确认 field 3 实际是 `audioTime`，真正的
`sdf transientInteraction` table 位于 field 6。因此，带音频时间的正常 durable 操作也可能被误拒。

## 原版证据

- `uq9/zq9`：root 共 7 个字段；field 3 写入 `audioTime`，field 6 写入 `sdf` table。
- `sdf/qqi`：metadata 的 field 0 是 required interactionId；field 1 timeout 当前明确无效。
- `tdf/oqi/wq9`：type 26 默认 transient，payload field 0 是 required interactionId，field 1 是
  nullable replacedByOp；root metadata 的 interactionId 由 payload ID 派生。
- `v69`：preview op 按 interactionId 放入内存 map；type 26 收集受影响实体、清除两组临时 cache、
  删除该 interaction。该分支不修改 durable CRDT，也不读取 replacedByOp。

## 修复

- 新增 `OriginalTransientInteractionOperation.ets`，严格解码 root field 6、metadata、type-26 payload
  和 optional replacedByOp；缺 ID、root/payload ID 不一致、timeout、未知字段均在写前 deferred。
- 新增 note-scoped `OriginalTransientInteractionStore`。preview operation ID 仅驻留内存，结束不存在的
  interaction 幂等，笔记间隔离，杀进程后自然清空，不新增数据库表或 v55 迁移。
- type 26 接入 `OriginalPageOperationApplier`。合法事件只清理内存状态并返回 applied，让 durable inbox
  的顺序、精确重试和 cursor metadata 正常推进，不写 page/entity/CRDT model。
- 修正统一路由和 `OriginalModifyPositionsOperationApplier`：以 field 6 presence 判断 transient；field 3
  继续作为合法 audioTime。此前 Phase 75/ADR-0053 对字段号的审计结论同步纠正。
- NOTE_BUNDLE 继续拒绝 transient；普通 transient preview 也继续 deferred，直到有原版等价的 view-model
  preview reducer。当前不会把 preview 污染 durable model，也不虚报实时协作视觉闭环。

## 验证

- ArkTS fixture 覆盖 interaction ID、optional replacedByOp、note 隔离、duplicate end、missing metadata、
  ID mismatch、timeout、unknown field，以及带 audioTime 的 durable type 2 正常写入。
- 新增 `d02-transient-interaction.mjs`，覆盖内存生命周期、重启丢弃、end 后 durable head 继续 drain、
  malformed head 保持阻塞、字段守卫和 NOTE_BUNDLE 边界。
- 全量桌面 replay：`TOTAL=65 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；仅保留仓库既有 warning。未启动模拟器/真机，也未执行设备 Hypium。

## 剩余边界

本阶段完成 type 26 的生产解析、顺序与内存清理，统一生产路由达到 **22/31**；剩余 **9 类**为
5、6、18、19、20、21、29、30、31。原版 incoming transient preview 的实体级临时渲染、缓存填充、
peer cursor/drag/ink 预览仍未闭环，因此仍需后续根据原版 view-model consumer 实现，不能用 durable
no-op 或数据库写入伪装原生体验。Goal 继续 active。
