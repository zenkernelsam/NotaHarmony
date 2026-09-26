# ADR-0714 — 原版 1.4.2 贴纸包管道登记为混合边界版本差

日期：2026-09-29
状态：已登记（版本差·混合边界；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-770-original-sticker-pack-pipeline.md`
Replay：`docs/migration/replays/d02-original-sticker-pack-pipeline.mjs`
上游：ADR-0708、Phase 763（stickers.apk 内容面）

## 背景

Phase 763 登记了 `stickers.apk` split 的 39 包 ~2985 webp 资产。
Phase 770 恢复其运行时侧：`pq3` 安装器采用
**split-first / CDN-fallback** 双源解析，`bwg` 校验目录合法性，
`hwg` 维护已安装集 + 完成事件流，`Download/Prefetch` 两个
CoroutineWorker 共享 `iwg`+`hwg`。

## 决策

登记为**版本差·混合边界**：

1. 39 包 split 资产为本地内容——若采纳贴纸功能，可直接以
   rawfile 打包进 Harmony HAP；
2. 安装器架构绑定 Android split-APK 机制（`stickers` split 目录
   解析），Harmony 无 split 等价物——需重设计为 rawfile/内部目录；
3. CDN 回退（`cdn`/`sticker.pack.delivery`/`version` 键）与商店
   目录属后端，维持 fail-closed；
4. 本阶段不移植任何管道——贴纸 UI/资产整合由独立 Phase 判定。

## 后果

- `d02-original-sticker-pack-pipeline.mjs` 钉住双源解析顺序、
  校验器扩展名集、CDN 键族与双 Worker 依赖签名。
- T-042 输入补齐贴纸簇"资产 + 管道"双侧证据。
