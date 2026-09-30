# Phase 1293 证据 — data/note/assets 资产同步

来源：`data/note/assets/*`。

## 组件

```
NoteAssetDatabase extends x5c    // Room 资产库（文件索引/状态）
NoteAssetTransferWorker          // CoroutineWorker 基类
    extends CoroutineWorker {
        p29 noteAssetsRepository  // 资产仓库
        c(k19)                    // 抽象传输任务
    }
NoteAssetDownloadWorker extends NoteAssetTransferWorker  // 下载
NoteAssetUploadWorker   extends NoteAssetTransferWorker  // 上传
```

`p29`=noteAssetsRepository；`k19`=传输任务记录（asset
id+方向+重试）—— 双向资产同步（下载缺失/上传新增）。

## 语义

**笔记资产同步** —— Room 资产库 + Worker 基类驱动
下载/上传 —— 图片/录音/附件的云端同步（断点续传/
重试）。

## Harmony 决策

CoroutineWorker → `WorkScheduler`；资产仓库 →
`rcp`/`http`+`relationalStore` —— 资产同步语义保真。

## 产出

- fixture `d02-asset-sync.mjs`（10 断言）。
- ADR-1237；中文报告。
