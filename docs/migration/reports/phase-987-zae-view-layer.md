# Phase 987 报告 — `zae` 统一视图层

## 范围

zae/uae/yae/tae/xae/lv2.U·V·W。纯审计。

## 原版发现

- `zae` = 三 root（r29/vt9/zgb）统一视图；`uae` 双
  discriminator 承载 r29+zgb，`yae` 承载 vt9。
- **`c()` 直返源 mmap ByteBuffer**——defer 写零重编码。
- `tae`/`xae` = 共享 uq9-holder 迭代器（复用实例，
  read-only remove 抛错）。
- `lv2.U/V` 补齐 vt9/zgb 物化器；`lv2.W`=s83 墓碑。

## 产出

- 证据：`phase-987-zae-view-layer.md`
- Fixture：`d02-zae-view-layer.mjs`（17/17）
- ADR-0931；全量 Replay 见本提交。
