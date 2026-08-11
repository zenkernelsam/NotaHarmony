# Phase 96 修复总结：原版 Recording 删除与撤销

## 原版证据

- `n05/uoa/hpa/npa` 证明 1.0.3 录音列表提供 Delete，没有 rename 入口；pending 行原位替换为
  `Recording deleted` 与 `Undo`。
- 重新以 fallback 字节码读取被 JADX 跳过的 `kk9.invokeSuspend`：case 12 明确等待 10,000 ms
  后提交单个 entity ID；Undo 取消 job；`npa.f()` 在退出时把全部 pending ID 批量提交。
- 删除沿原版 entity visibility type 25 流程，属于 LWW tombstone，不删除 Recording metadata 或音频资产。

## 已完成修复

- 新增纯删除控制器，精确实现 10 秒 optimistic pending、窗口内 Undo 零写入、到期单提交与退出批量
  flush；失败后撤掉 pending，使未改变的录音重新显示。
- RecordingPanel 增加 Delete；pending 行保持原位置并显示 Undo。pending 录音立即退出累计播放时间线和
  AudioLinked segment eligibility；删除当前播放项会卸载活动 player/FD，但 controller 仍可继续使用。
- 新增精确 DELETE_ENTITIES payload table encoder：只设置 entityDeletes，按原顺序去重，完整保留
  uint32 timestamp 与 uint16 site。
- `OriginalRecordingStore.deleteVisible()` 在 persistence mutex 和单事务内验证可见目标、分配稳定 operation
  identity、复用现有原版 visibility reducer、刷新 `has_recordings`，并将同一 payload 作为
  `ORIGINAL_DELETE_ENTITIES` 记入 operation log；任一步失败全部回滚。
- 边修边审发现并修复旧 `OriginalDeleteEntitiesOperation` 的匿名对象类型，使该 reducer 首次进入 default
  生产编译图时不再触发 ArkTS 结构类型错误。
- 补齐 Recording 新增字符串的中英文资源。严格按 1.0.3，不新增无证据的 rename UI。

## 验证

- 专项 replay：`recordingDelete=ten-second-undo-batch-lww-payload-journal`。
- 全量桌面 replay：`TOTAL=82 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`；仅有项目既有 warning。
- 未启动模拟器或真机。

## 剩余边界

本阶段闭环本地原版删除体验、visibility materialization 与待上传 journal，但项目尚无生产
`OperationSyncTransport`，因此不虚报已上传至 Notability 私有服务或收到 ACK。录音采集、audio focus/输出
路由、设备 codec/声音体验仍待后续；波形在找到更强的 1.0.3 证据前不按想象添加。Goal 保持 active。
