# Phase 701：原版 IMAGE 全生命周期组合矩阵 — 收口审计

handover P1(b)：在 Phase 280~699 已覆盖插入/裁切/翻转/旋转/命中/剪贴板/
拖放/撤销重做/资产引用完整性后，本轮把 IMAGE 链路的五段生命周期
（insert → persist → undo/redo → restart → import/export/sync）放进
同一 Replay 矩阵复核接缝。

## 审计范围

按 surface 逐段核对接缝不变量：

- **入口汇聚**：相册/拍摄/剪贴板/拖放四入口 → 同一
  `insertOriginalPhotos` → `commitOriginalPhotoInsert`。
- **历史→物化次序**：零 hash pending draft（`pending-original-image-*`）
  先 `prepareHistoryMetadata`（PUSH/NONE 校验），
  `commitOriginalImageInsert` 在 assetMutationMutex 内物化真
  assetHashBits 后才 `undoRedo.push`；过期页双守
  （isHistoryPageContextCurrent / isPhotoContextCurrent）。
- **资产完整性**：写入侧 sha512Hex≠storageHash 即 throw（内容寻址）；
  读取侧 `readVerifiedOriginalAsset` size 校验；canonical→legacy
  hash 回退解析。
- **undo/redo 图片刷新**：`actionTouchesImages` 覆盖
  ADD/ERASE-DELETE/TRANSFORM 三类；apply 路径
  `refreshImages && actionTouchesImages` → `refreshImageAssets`；
  UndoRedoManager 对 before/afterImages 双向 estimateImages；
  `strictPageElementOrder` null 即 throw（fail-closed）。
- **重启加载**：`refreshImageAssets` 先释放、按 storageHash 去重、
  双 generation 守。
- **导出**：IMAGE → `addAsset{assetHashBits,fileName,mimeType,fileSize}`
  + 背景 pdf metadata；逐资产 resolve + readVerified 后写入包。
- **导入/同步**：`storeImportedOriginalAsset`（NoteImporter 5 处）
  与 `receiveOriginalImageAsset` 复用同一事务写入路径，
  `becameAvailable → assetAvailabilityHub.publish`。

## 验证

- 新 Replay：`d02-original-image-lifecycle-matrix.mjs`（17 断言）。
- 全套件重跑通过后记录于修复总纲。

## 结论

IMAGE 五段生命周期接缝不变量全部在位，无代码变更需求（纯审计
收口阶段）。
