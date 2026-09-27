# Phase 925 报告 — `lv2` 物化器族实名

## 范围

向量→List 物化层实名。纯审计。

## 原版发现

- lv2.* 统一模式：长度门+m18.S/E buildList+逐位
  访问器；覆盖路径/位置/目标/墓碑/op 全部向量。
- hw3.I 空表、di7 范围迭代器、ei7/nl8 字节包装。

## Harmony 核对

解码通道对齐。

## 产出

- 证据：`phase-925-lv2-materializers.md`
- Fixture：`d02-lv2-materializers.mjs`（23/23）
- ADR-0869；全量 Replay 798 文件绿。
