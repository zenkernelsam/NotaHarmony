# ADR-0930 — 导出/分享 NoteBundle 生产者

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `haa` = 32 序数 op 类型枚举全表（NONE→MODIFY_COMMENT）。
- `fsi.P` = 导出过滤：排除 transientInteraction 非空 +
  TRANSIENT_INTERACTION_ENDED(26) + PEER_INTERACTION(29)。
- `yk9` = 导出生产者：过滤→双键排序（k79×2）→池化
  builder→`q4j.c` 写→finish→LE 复读→`ybg.c` 校验→
  `ree.b` **二次序列化**出最终字节。
- 同函数收集资产清单：SET_METADATA/CREATE_PAGE→
  PageBackground→PDFAsset(cba)，CREATE_BLOCK→
  ImageAsset(cp5)，MODIFY_PAGE/CREATE_RECORDING→pa0；
  按 ua0 hash 去重；`O` 参数控制是否含录音；
  transient op 跳过资产收集。

## Harmony 决策

等价：导出包剔除 transient/collab op + 资产清单随包；
写后复读校验保留。

## Parity 状态

等价。

## 验证

- `d02-export-bundle.mjs`：47/47 通过。
