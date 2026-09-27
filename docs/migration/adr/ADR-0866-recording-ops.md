# ADR-0866 — `yn2`/`ke8` 录音 op 读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `yn2` = CreateRecording{recording:akb@0,
  startTime:ulong@1, endTime:ulong@2, name:String@3,
  segmentation:ukb[]@4(16B 结构向量), zIndex:tmf@5}。
- `ke8` = ModifyRecording{recording:qo5@0, name:z2d@1,
  segmentation@2, zIndex:tmf@3}。
- `ukb` 16B 段元素 = 音频段区间标记。

## Harmony 决策

录音 op 编码对齐：akb 资产 + ULong 起止 + ukb[]
分段；修改侧 setter 包装。

## Parity 状态

等价；zq9 全部 op 载荷读侧闭合。

## 验证

- `d02-recording-ops.mjs`：14/14 通过。
- 全量 Replay 795 文件绿，见 Phase 922 提交。
