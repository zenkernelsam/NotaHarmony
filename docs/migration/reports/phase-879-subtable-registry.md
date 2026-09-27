# Phase 879 报告 — 余子表实名登记

## 范围

关闭 875 遗留六子表（akb/dp5/qqe/z1d/m2d/lxc），toString
实证字段语义。纯审计，无源改动。

## 原版发现

- `akb`=RecordingAsset{wa0}；`dp5`=ImageAsset{wa0,qed}；
  `qqe`=TextSelection{cxc,cxc}；`z1d`=SetBool{Boolean}；
  `m2d`=SetPageBackground{nz9}；`lxc`=SeqMove{cxc toId}。
- setter 包装族闭合：`?2d` 单字段族 + z1d/m2d/lxc 语义命名；
  z1d 实测用于 `me8` MODIFY_STYLE（v/u/t 三槽），`l2d` 用
  裸 Boolean + m2d。
- `u5j.s` moveTo 链：Integer 页索引→`bfj.b` cxc→`egh.a` lxc。
- `akb`/`dp5` 复用 `wa0` 统一资产元数据。

## Harmony 核对

moveTo/backgroundWinner ↔ SeqMove/SetPageBackground；
RecordingAsset/ImageAsset ↔ 录音/图像资产登记；z1d ↔
布尔 setter 槽。

## 产出

- 证据：`phase-879-subtable-registry.md`
- Fixture：`d02-subtable-registry.mjs`（23/23）
- ADR-0823；全量 Replay 与双 HAP 结果记录于提交。
