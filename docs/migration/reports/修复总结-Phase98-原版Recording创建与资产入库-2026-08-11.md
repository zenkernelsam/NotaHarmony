# Phase 98 修复总结：原版 Recording 创建与资产入库

## 原版证据

- `re0` 将文件复制到 `assets/pending`，复制过程中以 SHA-512 求摘要；`aa6` 每八字节按 little-endian
  读成一个 unsigned long，`ba6` 再按 little-endian 写回，因此 canonical 资产名就是 128 位 SHA-512 hex。
- `skb` 拒绝零字节录音，先保存资产，再以临时文件名、null segments、显式 zIndex 0 创建 Recording；无论
  成功还是失败，最终都会删除已交接的临时录音。
- `iaj` 的 CREATE_RECORDING 精确包含 recording metadata、startTime、endTime、name、segmentation、
  zIndex 六个字段；Recording identity 来自承载它的 operation identity。

## 已完成修复

- `AssetDigest` 新增原版 SHA-512 到八个 little-endian uint64 decimal word 的无损转换，并校验重新序列化
  后与 canonical SHA-512 hex 完全一致，不再混用早期逗号分隔 compatibility key 与资产文件名。
- 新增合法 FlatBuffer CREATE_RECORDING encoder：写入 64-byte inline AssetHash、fileName、mimeType、
  uint32 fileSize、start/end、name=fileName、缺省 segmentation 与 zIndex=0，并由现有生产 decoder round-trip。
- 新增流式资产入库：固定 64 KiB 缓冲复制临时录音并同步求 SHA-512，pending 文件 fsync 后原子 rename 到
  `assets/final/<128 hex>`；canonical 文件已存在时逐字节确认相同才复用。
- 以 `assetMutationMutex -> editorPersistenceMutex` 固定锁顺序；单一 DB 事务内分配 operation identity、运行
  `OriginalRecordingOperationApplier`、将 canonical `note_asset` 提升为本地可用并迁移 legacy key，最后把同一
  payload 写入 operation log，任一环节失败均 rollback。
- 文件补偿只删除本轮新建的 final，绝不误删已有共享资产；pending 与已交接 capture 临时文件无论成功失败都清理。
  边修边审补上两处窄故障窗：源文件复制期间大小变化会拒绝提交；重复资产比较的两个 FD 即使第二次 open 或任一
  close 失败，也按嵌套 finally 独立释放。
- `NotePage` 新增未暴露 UI 的持久化桥接，使完整模块进入 `note@default` 生产编译图，成功后刷新 Recording 列表。
  当前仍没有 Record 按钮或运行时权限请求，避免 Phase 99 交互状态尚未闭环时提前开放半成品。
- 新增 ArkTS digest/payload 测试、专项 replay 与 ADR-0075；内部 operation type 新增
  `ORIGINAL_CREATE_RECORDING`，供精确原版 payload 的本地 journal 分类。

## 验证

- 专项 replay：`recordingPersist=sha512-atomic-create-reducer-journal-cleanup`。
- 全量桌面 replay：`TOTAL=84 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`；仅有项目既有 warning。
- 未启动模拟器或真机，未执行设备 Hypium、麦克风、codec、权限弹窗或录音文件系统体验验收。

## 剩余边界

Phase 99 可加入运行时麦克风权限和 Record/pause/resume/stop UI，将成功 stop 的结果传入本阶段桥接，并完善
busy/error、拒绝权限与退出时 active recording 策略。audio focus/interruption、真实 codec/声音质量及设备权限行为
仍需后续实现和集中验收；私有同步 operation upload/ACK 也尚未因此完成。Goal 保持 active。
