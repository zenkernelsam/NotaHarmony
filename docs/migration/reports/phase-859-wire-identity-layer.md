# Phase 859 报告 — 线协议身份层登记

## 范围

登记原版操作线协议的「身份层」：haa payload-type 判别枚举、uq9 Op
信封、qo5 操作 Id、r29 NoteBundle 根表、utf 内联 UUID，并逐字段核对
Harmony 解码实现。纯审计阶段，无源改动。

## 原版发现

- `haa`：32 项 byte 枚举 = 全量操作判别表（SET_METADATA=1 起，
  MODIFY_COMMENT=31 止；NONE=0 为越界回退）。
- `uq9` Op 信封 7 字段：id@0 必填、clientTime/serverTime/audioTime
  三个 u64、payloadType@4、payload@5、transientInteraction@6。
- `qo5` Id = site(u16)+timestamp(u32) 八字节复合。
- `r29` NoteBundle 8 字段根表；`utf` 16 字节内联 UUID
  （`xwd` struct 基座，区别于 `cee` 表基座——两套读取布局）。

## Harmony 核对

- 字段编号、宽度、必填性逐一对齐（fixture 41 断言含 31 值枚举全量映射）。
- `payloadTypeKnown` 门镜像 nz3-NONE 回退；serverTime 必填门镜像
  synced 语义；显式字节/计数上界为有意加严。
- transientInteraction@6 登记为可空副信道，编码器侧已有同语义实现。

## 产出

- 证据：`phase-859-wire-identity-layer.md`
- Fixture：`d02-wire-identity-layer.mjs`（41/41）
- ADR-0803；全量 Replay 与双 HAP 结果记录于提交。
