# ADR-1237：资产同步 Worker

## 状态

已接受（Phase 1293）。

## 决策

`NoteAssetTransferWorker`+`Download`/`Upload`+Room →
Harmony `WorkScheduler`+`rcp`/`http`+`relationalStore`。

## 理由

`NoteAssetDatabase`(x5c Room)+`NoteAssetTransferWorker`
（abstract CoroutineWorker+`k19` 协程续体+`p29`
noteAssetsRepository）+`Download`/`Upload` 子类 —
— 双向资产同步（图片/录音/附件上传/下载）。

## 后果

Harmony 资产同步 = WorkScheduler+http+Room —
— 资产传输语义保真。
