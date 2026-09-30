# Phase 1341 证据 — 资产管理层

来源：`data/{AssetAvailabilityHub,AssetDigest,
AssetTemporaryArtifactCleanup,OriginalAssetReferenceStore,
OriginalPageInAssetState,ImageAssetPackageStore}.ets`。

## `AssetDigest` = SHA-512 内容哈希

```
sha512Digest / sha512Hex（cryptoFramework.createMd SHA512）
originalAssetHashBitsFromSha512(bytes):
  必须 64 字节 → 原版资产 hash bits（对照原版资产寻址）
```

→ 资产 = SHA-512 内容寻址（`originalAssetHashBits` 对接
原版资产哈希语义）。

## `AssetAvailabilityHub` = 资产可用性 pub/sub

```
AssetAvailabilityHub + assetAvailabilityHub 单例
  —— 资产就绪/失效事件订阅（异步下载完成后通知）
```

## `AssetTemporaryArtifactCleanup` = 临时工件清理

```
cleanupInterruptedAssetArtifacts(filesRoot):
  assets/pending（pending_asset_\d+_\d+.tmp）
  assets/trash（deleted_asset_\d+_\d+_\d+.tmp）
  —— 中断的写/删临时文件在首个 DB 初始化边界清理
    （安全进程边界）
```

→ 临时资产工件 = pending/trash 目录 + DB-init 边界清理
—— 崩溃安全（中断不残留）。

## Harmony 决策

资产 = SHA-512 内容寻址+可用性 hub+临时工件 init 清理
—— 对照原版资产传输/清理语义。

## 产出

- fixture `d02-asset-layer.mjs`（10 断言）。
- ADR-1283；中文报告。
