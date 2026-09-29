# Phase 1000 报告 — 缩略图上传 + nr1 依赖补全

## 范围

xqf multipart 上传端点；nr1 五个剩余构造依赖
（ssf/qr1/jl3/sxa/v2f）身份确认。纯审计。

## 原版发现

- `xqf`：`POST /images/thumbnails`（@Multipart）——
  noteId 文本 part + siteId + logicalTime +
  `wi8` 缩略图二进制 part + Accept 头 → Unit。
- `ssf` = {q75, xrf, vs4, pce, sfb} 服务组件；
  `qr1` = {pce×2}(Context+dbe 路径 lazy)；
  `jl3` = {pce×2, sfb}(cx6)；`sxa` = {Context}；
  `v2f` = `{t2f a()}` 时钟接口。
- `t5b` = kotlin Function0（Provider 基）。

## Harmony 决策

fail-closed；本地缩略图不受影响。

## 产出

- 证据：`phase-1000-thumbnail-and-deps.md`
- Fixture：`d02-thumbnail-upload.mjs`（10/10）
- ADR-0944；全量 Replay 见本提交。
