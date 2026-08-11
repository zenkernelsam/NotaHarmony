# Phase 79 修复总结：原版 PeerInteraction 内存分流

日期：2026-08-11

## 问题

原版 payload type 29 `PEER_INTERACTION` 尚未接入 Harmony 的统一生产路由。它若进入 durable inbox，
会被永久 deferred 并阻塞后续队头；若直接逐条写入模型或逐条更新 peer 状态，又会破坏原版按批次
合并、旧 cursor 继承和 malformed-last 丢弃语义。

## 原版证据

- `yda/i9j/u76/fqa/qqe/cxc`：payload field 0 是 optional cursor，field 3 是 selected entity ID vector，
  field 4 是 POINTER/PEN/HIGHLIGHTER/ERASER，field 5 是 optional text selection，field 6 是
  recordingInProgress；field 1/2 当前无 writer/consumer。
- `wq9/zq9/uq9`：type 29 默认 transient，root field 6 metadata 的 interactionId 等于 operation ID。
- `mzc/v69`：durable model replay 前先抽出 type 29；忽略本机 site，每批同一远端 site 仅保留最后一条
  raw operation。最后一条 malformed 时整站点本批不更新，不能回退到较早合法值，但仍继续其他模型操作。
- `tj8/aea/zda/uva`：peer/pending map 只驻留内存；winning payload 没有 cursor 时继承批次前旧 cursor。

## 修复

- 新增 `OriginalPeerInteractionOperation.ets`，严格解析完整 payload、root field-6 metadata 与 text
  selection SeqId；校验 identity、finite cursor、reserved/unknown fields，并将 selected vector 限制为
  10,000 项后按原版 Set 去重。未知 tool 回退 POINTER，任意非零 recording byte 视为 true。
- 新增 note/site-scoped 内存 store，提供 defensive copy、旧 cursor 继承、本机 site 忽略和 clearNote；
  不新增数据库表，进程重启自然丢弃 peer presence。
- `IncomingOperationSyncCoordinator` 在 durable reducer 前对整个 incoming batch 分流：同 site last raw
  wins，只解码 winner，malformed winner 计入 discarded 且保持旧状态。生产创建时立即验证 localSiteId，
  返回 operation/update/discarded 三项计数。
- type 29 接入 `OriginalPageOperationApplier`，无论 peer 转换成功或按原版被丢弃，都以零 page/entity/CRDT
  写入消费 durable inbox 位置，使原始字节幂等、队列顺序和 server-time cursor 正常推进。
- NOTE_BUNDLE 继续拒绝 transient，避免历史/bootstrap 包恢复临时 presence。

## 验证

- ArkTS fixture 覆盖完整字段、重复 selected ID、未知 tool、非零 bool、非法 metadata/reserved/extension、
  note/site 隔离、本机忽略、defensive copy、同批 last-wins、批次前 cursor 继承、malformed-last 丢弃和
  零 durable model 写入。
- 新增 `d02-peer-interaction.mjs`，覆盖内存生命周期、批次合并、restart 丢状态、inbox/cursor 继续推进、
  源码路由守卫和 NOTE_BUNDLE 边界。
- 全量桌面 replay：`TOTAL=66 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；仅保留仓库既有 warning。未启动模拟器/真机，也未执行设备 Hypium。

## 剩余边界

本阶段完成 type 29 的生产解析、批次分流与 pending peer 内存状态，统一生产路由达到 **23/31**；
剩余 **8 类**为 5、6、18、19、20、21、30、31。原版 roster/displayName/color consumer、45 秒 presence
过期、10 秒 recording 过期，以及远端 cursor/selection/recording 的实际 UI 渲染仍未闭环，后续必须继续
依据原版 consumer 实现，不能把内存状态接通虚报成接近原生的协作视觉体验。Goal 继续 active。
