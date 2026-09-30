# ADR-1283：资产管理层

## 状态

已接受（Phase 1341）。

## 决策

资产 = SHA-512 内容寻址（`originalAssetHashBits`）+
可用性 pub/sub hub + pending/trash 临时工件 init 清理。

## 理由

`AssetDigest` SHA-512（64 字节）对接原版资产哈希；
`AssetAvailabilityHub` 资产就绪事件订阅；
`AssetTemporaryArtifactCleanup` 在首个 DB-init 边界
清理 `assets/pending`/`trash` 中断临时文件 —— 崩溃
安全（中断不残留）。

## 后果

资产内容寻址+事件驱动+崩溃安全清理 —— 对照原版
资产传输语义。
