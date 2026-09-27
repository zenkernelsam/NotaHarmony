# ADR-0870 — `yda` PeerInteraction + `u76` PeerTool

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `yda` = PeerInteraction{cursorPosition:fqa@0,
  selectedEntities:qo5[]@3, tool:u76@4,
  textSelection:qqe@5, recordingInProgress:bool@6}
  ——协同光标广播 op（haa type 29，ar6 里程碑 8）。
- `u76` = PeerTool{POINTER,PEN,HIGHLIGHTER,ERASER}
  对端工具简化集（区别于本端 u16 全集）。

## Harmony 决策

协同 op 编码对齐；PeerTool 枚举独立。

## Parity 状态

等价。

## 验证

- `d02-peer-interaction-yda.mjs`：9/9 通过。
- 全量 Replay 799 文件绿，见 Phase 926 提交。
