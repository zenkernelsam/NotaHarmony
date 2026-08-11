# Phase 94 修复总结：原版 Operation 音频时间保真

## 原版证据

- `uq9.j()` 明确从 root field 3 读取 nullable uint64 `audioTime`；field 6 才是
  `sdf transientInteraction`。`wq9` 的 operation creation metadata 同样单独持有 audioTime。
- `q06` 构造可播放 Ink 时，显式 audioTime 优先，缺失时回退 operation clientTime；`op7` 同时保存
  modifiedTime 与最终 audioTime，证明二者不能混为一个时间字段。
- `s1j.b()` 使用 unsigned 比较判断当前播放时间与实体音频区间，说明 Harmony 必须保留完整 uint64，不能
  经 JavaScript `number` 损失精度。

## 已完成修复

- `OriginalSyncedOperationEnvelope` 新增 nullable `audioTime`，严格读取完整 8-byte field 3；
  `IncomingOperationSyncCoordinator` 将其传播到入站 operation，applier 调用前也能直接取得该值。
- 修复边修边审发现的 NOTE_BUNDLE 遗漏：嵌套 `uq9` 不再把 field 3 当 transient；audioTime 改为
  `readUint64Decimal(3)`，真正 transient 改按 field 6 table presence 判断。带 audioTime 的合法历史
  bundle 不再被误拒绝，真正临时交互仍不写 durable model。
- 数据库 v57 升至 v58，新增 `original_applied_operation_time`：按 note/op identity 保存 clientTime、
  nullable wire audioTime 和 payloadType；只有 reducer 成功后才在同一事务写入，因此 malformed、unknown、
  deferred operation 不会污染可查询时间模型。
- 普通 inbox 成功应用和 NOTE_BUNDLE 成功 bootstrap 共用同一持久化入口；精确 retry 幂等，相同 identity
  的不同时间元数据会报 corruption。笔记删除通过外键级联清理。
- 数据库初始化会从历史 APPLIED inbox raw `uq9` 回填缺失行，并先校验 raw 与 inbox identity/client/server/
  payload metadata 一致。新增 note-scoped reader，同时返回 nullable `audioTime` 与原版等价的
  `effectiveAudioTime = audioTime ?? clientTime`，按精确十进制时间排序。

## 验证

- ArkTS fixture 覆盖无 audioTime、显式 `99`、NOTE_BUNDLE child audioTime `19`、field 6 transient 分离和
  coordinator 传播。
- 新增 ADR-0071 与 `d02-operation-audio-time.mjs`；专项覆盖 v57→v58、uint64 max、fallback、排序、
  非法十进制、identity conflict、回滚、级联、历史 inbox backfill 与 NOTE_BUNDLE wiring。
- 全量桌面 replay：`TOTAL=80 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`；仅有 RDB 异常提示与项目既有弃用 API 等 warning，无编译错误。
- 未启动模拟器或真机。

## 剩余边界

本阶段完成的是 audio-ink 所需的数据保真和查询基础，不虚报随播放时间高亮 Ink、渐显动画、波形或设备
像素验收。v58 可自动回填历史 APPLIED inbox；旧 schema 没有 NOTE_BUNDLE 的 applied marker，因此已物化的
历史 NOTE_BUNDLE 不能在启动迁移时盲目重放，会在其下一次合法 bootstrap 时幂等补齐时间行。下一阶段应继续
直读原版 audio-linked entity/materialization 与 renderer consumer，再接当前 Recording 累计播放时间。
