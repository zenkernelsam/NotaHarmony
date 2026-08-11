# Phase 88 修复总结：原版 Recording 读取 Consumer

日期：2026-08-11

基线：`083682d docs(audit): correct shape rich text consumer boundary`

范围：可见 Recording materialization、segment/hash 校验、资产可用性边界

## 原版证据

- `gkb/tab/fkb` 表明 Recording 由 CREATE identity 标识，start/end 与 asset metadata 不可变，name、
  segments、zIndex 是三个独立 LWW register；缺省 segments 为 `[start,end]`，缺省 zIndex 为 operation
  clientTime。
- `yn2/ukb/wa0` 保持 uint64 时间、segment 边界、八 word AssetHash、非空文件名/MIME 和正 fileSize。
- DELETE_ENTITIES 使用统一 visibility winner；资产 metadata/reference 存在不等于音频 bytes 已到达。

## 实际修复

- 新增 `OriginalRecordingStore.listVisible()`，从 `original_recording_state` 与 canonical visibility
  联表读取当前可见录音，使用已经物化的 name/segments/zIndex LWW 值。
- segment 与 zIndex 全程保留十进制 uint64 字符串，不经过 JavaScript Number；严格解析八个 canonical
  uint64 hash word，并按 unsigned zIndex、CREATE timestamp/site 稳定排序。
- 复用 `note_asset`，同时识别 canonical 128 hex 与旧 word key，向未来播放器显式暴露
  MISSING/PENDING/READY/FAILED。fileSize/MIME 冲突和 FAILED 资产不会误报 READY。
- 当前只建立 read consumer；没有虚报录音采集、播放器、波形、segment seek、远端 bytes 到达或 codec
  已完成。

## 验证

- 新增 `OriginalRecordingStore.test.ets` 并注册到测试 suite；precision、越界、hash、uint64 排序均通过
  ArkTS 编译。
- 新增 `d02-recording-consumer.mjs`，覆盖 tombstone、materialized segments、uint64 z-order 和四态
  资产合同；全量桌面 replay 为 `TOTAL=74 FAILED=0`，专项输出为
  `recordingConsumer=visible-lww-zorder-asset-state`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；只有项目既有 deprecated/exception-handling warning。
- 未启动模拟器、真机或 Hypium；Goal 继续 active。
