# Phase 904 报告 — `xgb`=`Realtime` 实名

## 范围

实名 op 元数据音频时间值类。纯审计。

## 原版发现

- `xgb` = `Realtime`：ULong 语义值类（无符号比较+
  十进制格式化）——录音实时位置。
- 链路：wq9.d(audioTime)/uq9 字段3/工厂参数/f8d.c。
- 边界澄清：创建侧 Realtime，线上读侧 tmf/long。
- 无符号家族闭环：mmf/ymf/tmf/xgb。

## Harmony 核对

audioTime ULong 读取对齐。

## 产出

- 证据：`phase-904-xgb-realtime.md`
- Fixture：`d02-xgb-realtime.mjs`（11/11）
- ADR-0848；全量 Replay 777 文件绿。
