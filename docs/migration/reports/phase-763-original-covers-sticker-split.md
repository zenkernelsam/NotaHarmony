# Phase 763：原版 1.4.2 封面资产与贴纸 split 登记

> 日期：2026-09-29
> 证据：`docs/migration/evidence/phase-763-original-covers-sticker-split.md`
> 上层处置：`docs/migration/adr/ADR-0708-original-1.4.2-version-delta-scope.md`
> Replay：`d02-original-covers-sticker-split.mjs`（5 断言，全绿）
> 性质：版本差证据登记；无 Harmony 代码变更。

## 登记结果

- `covers/`：10 个 PDF-1.7 笔记封面（纯色系 + journal/logo-pattern/
  stickers 预设贴纸页）；代码内枚举，无清单文件；
- `stickers.apk`：156 MB 独立 split，内置 **39 包 ~2985 个 .webp**
  贴纸（sticker_konana_academic 552 件最大），包目录与
  `feature_note_stickers__pack_*` 键一一对应；另有
  Download/Prefetch Worker 承担远端包扩展。

## 处置

- 封面 PDF：与 Phase 761 papertemplates 同型（PDF 底板渲染链）——
  版本差·待审；
- 贴纸商店：split-APK 分发机制 Harmony 无等价物，商店/下载链路
  fail-closed 登记；`save_as_sticker` 自制贴纸列为版本差·待审；
- Replay 5 断言全绿；无源码变更；T-042 输入。
