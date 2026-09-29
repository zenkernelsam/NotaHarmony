# ADR-0944 — `xqf` 缩略图上传 + nr1 依赖补全

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `xqf`：`@Multipart @POST /images/thumbnails` ——
  parts: noteId(nwb 文本 body)、siteId(short)、
  logicalTime(int)、thumbnail(`wi8` binary part)，
  header `Accept`；返回 Unit。
- `nr1` 剩余 deps：`ssf`(q75+xrf+vs4+lazy+mutex)、
  `qr1`(Context+dbe→lazy×2)、`jl3`(cx6→lazy×2+mutex)、
  `sxa`(Context 持有者)、`v2f`(接口 `t2f a()` 时钟)。
- `t5b` = Function0（`ca4` Provider 基接口）。

## Harmony 决策

缩略图上传 fail-closed；本地 PixelMap 缩略图不变。

## Parity 状态

fail-closed。

## 验证

- `d02-thumbnail-upload.mjs`：10/10 通过。
