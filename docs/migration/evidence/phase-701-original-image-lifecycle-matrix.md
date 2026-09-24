# Phase 701：原版 IMAGE 全生命周期组合矩阵 — 接缝审计（2026-09-24）

handover P1(b)：在 Phase 280~699 图片链路逐面收口后，把
IMAGE/undo/restart/import/export/sync 放到同一矩阵复核接缝不变量。
本文件记录矩阵覆盖的接缝地图（Harmony 侧锚点）。

## 入口 → 单一物化管线

- `NoteCanvasView`：`pickAndImportOriginalPhotos`（相册）、
  `captureAndImportOriginalPhoto`（拍摄）、
  `importOriginalClipboardImage`（剪贴板）、
  `importOriginalDroppedImages`（拖放）四条入口全部汇入
  `insertOriginalPhotos(imported, origin)`（startOriginalPhotoInsert /
  startOriginalCameraCapture / 贴图 / onOriginalImageDrop 共用
  commitOriginalPhotoInsert）。

## pending → 历史 → 物化

- `insertOriginalPhotos`：以 `OriginalImageInsertPersistencePlan`
  构造零 hash pending draft（`pending-original-image-{i}` id），
  `undoRedo.prepareHistoryMetadata(draftAction)` **先于**持久化提交；
  `StrokePersistence.commitOriginalImageInsert` 校验
  `HistoryEffect.PUSH` + `HistoryCoalesceTrack.NONE`，
  `prepareLocalOriginalImageAsset`（assetMutationMutex 内）产出真
  `assetHashBits` 后再 `undoRedo.push(action, prepared)`。
- 过期页双守：`isHistoryPageContextCurrent`（落盘历史仍可用）与
  `isPhotoContextCurrent`（丢弃来源页切换后的插入）。

## 资产完整性

- `ImageAssetPackageStore.writeOriginalImageAssetBytes`：
  `sha512Hex(arrival.bytes) !== storageHash → throw`（内容寻址）；
  `writeOriginalImageAssetBytesLocked` 在事务内，
  `store.beginTransaction()/rollBack` 保留回滚。
- `resolveOriginalAsset`：canonical storageHash 查询，回退
  legacyHash；`readVerifiedOriginalAsset` 读前 size 校验。
- `receiveOriginalImageAsset`（同步到达）与
  `storeImportedOriginalAsset`（.note 导入，NoteImporter 5 处调用）
  复用同一写入路径，`becameAvailable → assetAvailabilityHub.publish`。

## undo/redo → 资产刷新

- `actionTouchesImages`：ERASE/DELETE→removedImages、
  ADD_ELEMENTS→addedImages、TRANSFORM→before/afterImages 三类覆盖；
  apply 路径 `refreshImages && actionTouchesImages(action)` →
  `refreshImageAssets`。
- `UndoRedoManager` 对 TRANSFORM 的 before/afterImages 双向
  `estimateImages` 内存估算。
- `synchronizeElementArraysByOrder`：`strictPageElementOrder` 返回
  null（数组与 order 不一致）即 throw —— fail-closed。

## 重启加载

- `refreshImageAssets(generation, pageId)`：先 `releaseImageAssets`，
  按 `originalAssetStorageHash` 去重，`pageGeneration`/`assetGeneration`
  双代际守，逐块 `loadImageAsset`。

## 导出

- `NoteExporter`：IMAGE 元素 → `addAsset{assetHashBits,fileName,
  mimeType,fileSize}`；背景 pdf 同样入列；逐个
  `resolveOriginalAsset` + `readVerifiedOriginalAsset` 后才
  `writer.addEntry`。

## 结论

组合矩阵 17 断言全绿：四条入口单管线、历史元数据先行、内容寻址
写入、三类 undo/redo 图片刷新、严格 order 契约、重启去重加载、
导出校验读取、导入/同步共享写入——接缝无漂移。
