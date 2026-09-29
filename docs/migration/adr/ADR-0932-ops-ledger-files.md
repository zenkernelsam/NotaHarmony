# ADR-0932 — `.ops`/`.offsets`/`.fingerprints` 账簿

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `dbe` 路径族：`<notes>/<id>.ops`（op 字节流）、
  `<id>.offsets`（int32 索引）、`deferred/<id>/<row>
  .deferred`、`fingerprints/<id>/<site>.fingerprints`；
  `pr1` 提供 notes/deferred/client_ops_wal 三目录。
- `lv2.s0` = 指纹重建：mmap `.ops` + RAF 读 `.offsets` →
  逐 op 解析 id(slot4=site+ts)/serverTime(slot8) → 按
  site 分组写 LE 12B `{ts,serverTime}` 记录 →
  `hg4{site,len,crc32}` 集合入库。
- `kl1` = CRC32 计数流（写同时累计校验和）。
- `lv2.p` = 指纹目录孤儿清理；`lv2.t`=OpAck 物化器。
- 计数为 0 → 删除指纹目录 + pae 清零。

## Harmony 决策

等价：三层账簿 + 指纹随行入库 + CRC32 流式。

## Parity 状态

等价。

## 验证

- `d02-ops-ledger-files.mjs`：25/25 通过。
