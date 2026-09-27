# Phase 926 证据 — `yda` = `PeerInteraction` + `u76`

## 目的

协同光标广播 op 实名（873 注册补全）。

## `yda` = `PeerInteraction`（toString 实证）

`PeerInteraction(cursorPosition=, selectedEntities=,
tool=, textSelection=, recordingInProgress=)`

| 访问器 | c(N) | 类型 | 语义 |
|--------|------|------|------|
| `j()` | c(4) | `fqa` | **cursorPosition**（光标位置） |
| `o(qo5,i)`/`l()`/`lv2.d0` | c(10) | `qo5[]` | **selectedEntities** |
| `n()` | c(12) | `u76` | **tool**（当前笔型） |
| `m()` | c(14) | `qqe` | **textSelection**（TextSelection） |
| `k()` | c(16) | bool | **recordingInProgress** |

- `haa.PEER_INTERACTION`（type 29）；
  ar6 PEER_INTERACTION=8 里程碑。
- 协同光标广播：位置+选中集+工具+文本选区+录音态。

## `u76` = PeerTool 枚举

`{POINTER=0, PEN=1, HIGHLIGHTER=2, ERASER=3}` ——
对端工具类型（光标/笔/荧光/橡皮）。

## Harmony 核对

`OriginalPeerInteractionOperation` 编码对齐；
u76 工具枚举与 u16 本端工具族区分（对端简化集）。

## 结论

协同 op 闭合——PEER_INTERACTION 协议五字段 +
PeerTool 枚举实名。
