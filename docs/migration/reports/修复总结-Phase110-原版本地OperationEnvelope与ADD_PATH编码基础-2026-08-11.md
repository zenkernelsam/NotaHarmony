# Phase 110 修复总结：原版本地 Operation Envelope 与 ADD_PATH 编码基础

## 原版证据

- 原版 `zq9.e/uq9` 的 operation 是七字段完整 FlatBuffer：identity、clientTime、nullable
  serverTime、nullable audioTime、payload type、payload table 和 nullable transient metadata。
  `zq9.a` 创建本地未同步 operation 时省略 serverTime，而不是显式写零。
- `uq9.q` 从完整 operation 的 field 5 跟随指针进入 payload。单独的 `ln2/dm2/gd/wd8/s83/yn2`
  payload 子表不能作为 reducer 的 `rawOperation`。
- 原版 `kt1.d/bt1` 在首批实际点创建 transient CREATE_INK；`kt1.c/u5j.a` 对 active Ink ID
  提交 actual/estimated ADD_PATH_ELEMENTS。空 actual 与空 estimated 不提交。
- `wq9` 把 type 26/29 默认分类为 transient，并让带 `_inProgressTransientId` 的 ADD 归入同一
  interaction。`oqi.a` 创建结束 payload；正常 finish 最终另建完整 durable CREATE_INK，再清理 transient，
  preview ADD 不进入 durable model journal。

## 边修边审发现的共同根因

- Phase 98–109 新增的 payload encoder 本身可以生成正确子表，但页面、Ink 等 reducer 调用
  `readOriginalPayloadTable(rawOperation, expectedType)`，要求完整 `uq9`。旧本地 writer 把子表直接赋给
  `rawOperation`，运行时会 deferred，因此 Phase 105–109 原报告中的生产闭环声明过早。
- Recording CREATE 直接从子表物化可以成功，但写入 `operation_log` 的仍是不可被 envelope reader 读取的
  子表。启动迁移、未来上传和 audioTime 读取都会遇到同一结构错误。
- 旧 ArkTS fixture 也把子表直接交给 production decoder；此前只编译 ohosTest、未运行设备 Hypium，故没有
  在运行态暴露。Phase 110 已更正 ADR-0073/0075/0082–0086 的历史边界，不保留虚假声明。

## 已完成修复

- 新增完整 `uq9` encoder：复制 payload root buffer 并让 outer field 5 直接指向复制后的 child table，保留
  child vtable 的相对布局；严格校验 identity、uint64 时间、payload type、root 和 transient identity。
- 新增通用 original-envelope parser 与 synced-envelope parser 分层。本地 writer 按原版省略 nullable
  serverTime；入站同步 parser 继续要求该字段存在，不能把未获服务端接受的本地 bytes 冒充 synced op。
- 页面 CREATE/visibility、Ink CREATE/visibility/style、Recording CREATE/delete 全部改为先构造完整
  operation，reducer 与 `operation_log.payload` 使用完全相同的 bytes；payload child 只存在于 encoder 内部。
- 启动时在 audio-time backfill 前只修复可真实提交的 Phase 98 CREATE_RECORDING child row：后续页面/Ink
  链会在 append 前 deferred，不可能留下 legacy journal。候选 child 先通过 CREATE_RECORDING schema decoder；
  完整行必须与数据库 identity/clientTime/payloadType/audioTime 一致且 serverTime 为空或零。冲突直接使初始化
  事务回滚；查询先全部读出并关闭 cursor，再更新同一表，避免游标失效。
- 新增 type 16 ADD_PATH_ELEMENTS encoder：target 为 inline Ink identity，actual/estimated 独立 nullable，
  但不能同时为空。新增 version 0 attributed BITS_32 append writer，不写 MOVE；支持 cubic 范围和无 cubic
  双点 line tail。
- 新增 type 26 TRANSIENT_INTERACTION_ENDED writer，保留 interactionId 与 nullable replacedByOp。当前只作为
  协议基础，不把没有 transient sink/认证 transport consumer 的 touch move 流虚报为完成，也不把 preview
  写入 durable operation log。

## 验证

- ArkTS fixture 已改为把 page/Ink/delete/modify payload 包成完整 operation 后交给生产 decoder，并新增
  actual+estimated、line-only append、durable/transient metadata、synced parser 拒绝本地 envelope 和
  type-26 replacement round-trip。
- 专项 replay 独立解析 root/vtable/payload 指针，模拟 child row 包装、完整行幂等、audioTime 保留和 metadata
  冲突拒绝，输出：
  `localOperationEnvelope=uq9-original-null-server-child-repair-add-path-transient-end`。
- 全量桌面 replay：`TOTAL=96 FAILED=0`。
- 执行 `hvigor clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，均为 `BUILD SUCCESSFUL`。
  ohosTest 仅证明测试源码和 HAP 可编译，没有运行 Hypium；默认包仍有既有异常声明/弃用 API/未签名 warning，
  无 ArkTS error。
- 删除 3 个本阶段临时 JADX dump；未修改原版 `decompiled_1.0.3`，未启动模拟器、虚拟机、真机或 Hypium。

## 仍待后续

- 需要先定义明确的非持久 transient sink/transport ownership，再接 touch move/up/cancel 的 CREATE/ADD/end
  preview 生命周期；不能为“看起来已接线”生成无人消费的 operation。
- 本地 center-path replacement、选区 color/width、Shape/Group outbound、其余格式与私有认证 upload/ACK
  仍未完成。Goal 保持 active，下一阶段继续按原版证据边修边补审。
