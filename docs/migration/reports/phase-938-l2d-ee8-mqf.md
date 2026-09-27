# Phase 938 报告 — l2d/ee8/mqf 字段级偏移

## 范围

三个 op 访问器→偏移钉死。纯审计。

## 原版发现

- l2d SetMetadata 8 字段镜像 a79：前四
  setter-wrapped，后四裸值。
- ee8 ModifyPDFField 5 字段（ua0+key+ww9
  +string+boolean）。
- mqf UpdateCheckbox 3 字段（qo5+cxc+bool）。

## 产出

- 证据：`phase-938-l2d-ee8-mqf.md`
- Fixture：`d02-l2d-ee8-mqf.mjs`（17/17）
- ADR-0882；全量 Replay 811 文件绿。
