# Phase 770 — 原版 1.4.2 贴纸包安装/下载管道登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-770-original-sticker-pack-pipeline.md`
ADR：`ADR-0714-original-sticker-pack-pipeline.md`
Replay：`d02-original-sticker-pack-pipeline.mjs`（6/6）

## 本阶段做了什么

补全 Phase 763（stickers.apk 内容面）的运行时侧：恢复贴纸包
安装器、校验器、下载状态登记与双 Worker 的协作结构。

## 发现

- `pq3`（implements `iwg`）：split-first / CDN-fallback 解析——
  先查 `stickers` split 安装目录下的包目录并经 `bwg` 校验，
  未命中走 `mo1` 远端下载。
- `bwg`：webp/png/jpg/jpeg 扩展名校验器。
- `mo1`：CDN 键族 `cdn`/`sticker.pack`/`.delivery`/`.version`。
- `hwg`：StateFlow 已安装集 + Channel 完成事件（`fwg` 四态）。
- `StickerPackDownloadWorker`/`StickerPackPrefetchWorker` 共享
  `iwg`+`hwg`，仅触发时机不同。

## 分类

ADR-0714 登记为**版本差·混合边界**：39 包资产可 rawfile 移植；
安装器绑 Android split 机制需重设计；CDN/商店目录维持
fail-closed。贴纸 UI/资产整合留待独立 Phase 判定。

## 验收

- Replay 6/6 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
