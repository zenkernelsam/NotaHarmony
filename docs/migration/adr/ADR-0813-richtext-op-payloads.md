# ADR-0813 — 富文本 op payload 模式登记（类型 7–14）

## 状态

accepted（文档+fixture，无源改动；Harmony 文本 op 层已等价）

## 原版契约（`decompiled_1.0.3`）

- zq9 映射：e46=INSERT_CHAR、f46=INSERT_STRING、pub=REMOVE_CHAR、
  qub=REMOVE_CHARS、f2c=REVIVE_CHARS、me8=MODIFY_STYLE、
  he8=MODIFY_PARAGRAPH_STYLE、io1=CLEAR_STYLE。
- 单点 ops：e46{cxc,int char,qo5}、f46{cxc,String,qo5}、
  pub{cxc,qo5}。
- 批量 ops：qub/f2c = {vector<cxc>(12B stride),qo5}，
  向量访问器越界 fail-fast（`Index out of range`）。
- io1 = {v01 range×2, boolean, qo5}。
- 目标一律为 `qo5` op-id（父文本块）；位置一律 `cxc`。

## Harmony 决策

`OriginalInsertTextPayloadEncoder` 覆盖 insert/remove/revive
（visible 判定 REVIVE vs REMOVE_CHARS）；
`OriginalRichTextStyleOperation` 覆盖类型 12–14；`OpTypes`
常量齐备。字段形态等价（位置序列化经 cxc/SeqId 层）。

## Parity 状态

等价。

## 验证

- `d02-richtext-op-payloads.mjs`：31/31 通过。
- 全量 Replay 与双 HAP 构建见 Phase 869 提交。
