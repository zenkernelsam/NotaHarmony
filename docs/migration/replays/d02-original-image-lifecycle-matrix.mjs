// D02 原版 IMAGE 全生命周期组合矩阵 — Phase 701（handover P1(b)）
// 把图片 insert → persist → undo/redo → restart load → import →
// export → sync arrival 放到同一矩阵校验接缝不变量：
//   1) 四条入口（相册/拍摄/剪贴板/拖放）汇入同一 insertOriginalPhotos 管线；
//   2) pending draft 零 hash + pending-original-image-* 先建历史元数据
//      （PUSH/NONE 校验）→ commitOriginalImageInsert 物化真 hash；
//   3) 资产写入内容寻址：sha512Hex !== storageHash → throw；
//   4) undo/redo 触碰图片的三类 action（ADD/ERASE-DELETE/TRANSFORM）
//      均触发 refreshImageAssets + strictPageElementOrder 不同意即 throw；
//   5) 重启加载：releaseImageAssets + storageHash 去重 + generation 守；
//   6) 导出：image → addAsset + resolveOriginalAsset +
//      readVerifiedOriginalAsset（size 校验）；
//   7) 导入/同步：storeImportedOriginalAsset / receiveOriginalAsset →
//      同一 writeOriginalImageAssetBytes 事务路径。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');

const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const store = read('note/src/main/ets/data/ImageAssetPackageStore.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const undo = read('note/src/main/ets/rendering/UndoRedoManager.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 1) 四入口 → 同一物化管线 ---
check(canvas.includes('pickAndImportOriginalPhotos') &&
  canvas.includes('captureAndImportOriginalPhoto') &&
  canvas.includes('importOriginalClipboardImage') &&
  canvas.includes('importOriginalDroppedImages'),
  'four ingress fronts feed the shared photo pipeline');
check(canvas.includes('private async insertOriginalPhotos(') &&
  canvas.includes('commitOriginalPhotoInsert(imported, origin)'),
  'all ingress paths commit via insertOriginalPhotos');

// --- 2) pending draft → 历史元数据先于物化 ---
check(canvas.includes('OriginalImageInsertPersistencePlan') &&
  canvas.includes("pending.id = 'pending-original-image-' + index") &&
  canvas.includes("assetHashBits: ['0', '0', '0', '0', '0', '0', '0', '0']"),
  'pending drafts carry zero hash + pending ids');
check(canvas.includes('this.undoRedo.prepareHistoryMetadata(draftAction)') &&
  canvas.indexOf('prepareHistoryMetadata(draftAction)') <
    canvas.indexOf('commitOriginalImageInsert'),
  'history metadata prepared before durable commit');
check(persistence.includes('async commitOriginalImageInsert(') &&
  persistence.includes('history.effect !== HistoryEffect.PUSH') &&
  persistence.includes('HistoryCoalesceTrack.NONE'),
  'commit requires non-coalesced PUSH history');

// --- 3) 资产内容寻址写入 ---
check(store.includes('const digestHex: string = await sha512Hex(arrival.bytes)') &&
  store.includes('original image asset SHA-512 does not match its declared hash'),
  'asset bytes are content-addressed (SHA-512 verified on write)');
check(store.includes('prepareLocalOriginalImageAsset') &&
  store.includes('mergePreparedLocalOriginalImageAsset') &&
  store.includes('assetMutationMutex.runExclusive'),
  'local asset prepare/merge runs inside the asset mutex + transaction');

// --- 4) undo/redo 触碰图片的三类 action ---
check(canvas.includes('action.removedImages.length > 0') &&
  canvas.includes('action.addedImages.length > 0') &&
  canvas.includes('action.beforeImages.length > 0 || action.afterImages.length > 0'),
  'actionTouchesImages covers ADD/ERASE-DELETE/TRANSFORM image fields');
check(/refreshImages && this\.actionTouchesImages\(action\)/.test(canvas) &&
  canvas.includes('this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId)'),
  'undo/redo refresh image assets when the action touches images');
check(canvas.includes('strictPageElementOrder') &&
  canvas.includes('page arrays and explicit element order disagree'),
  'element-order/arrays disagreement throws (strict order contract)');

// --- 5) 重启/换页加载：去重 + 释放 + generation 守 ---
check(canvas.includes('private refreshImageAssets(pageGeneration: number, pageId: string)') &&
  canvas.includes('this.releaseImageAssets()') &&
  canvas.includes('seen.has(storageHash)') &&
  canvas.includes('originalAssetStorageHash(block.assetHashBits)'),
  'refresh releases, dedupes by storage hash, and keeps generation guards');
check(undo.includes('estimateImages(action.beforeImages)') &&
  undo.includes('estimateImages(action.afterImages)'),
  'undo manager estimates image memory for transform actions');

// --- 6) 导出：image → addAsset + resolve + read-verified ---
check(exporter.includes("elementObjects.push({ kind: 'image', data: element.data })") &&
  exporter.includes('this.addAsset(assets, {') &&
  exporter.includes('assetHashBits: imageElement.assetHashBits'),
  'export materializes image elements + registers their asset');
check(exporter.includes('resolveOriginalAsset(assetRepository, metadata)') &&
  exporter.includes('readVerifiedOriginalAsset(asset, metadata)'),
  'export resolves + size-verifies each asset before packaging');
check(store.includes('legacyHash === storageHash') ||
  store.includes('await repository.getAsset(legacyHash)'),
  'asset resolve falls back to the legacy hash key');

// --- 7) 导入/同步：同一写入路径 ---
check(importer.includes('storeImportedOriginalAsset(this.db,') &&
  store.includes('export async function storeImportedOriginalAsset('),
  '.note import stores image assets through the shared write path');
check(store.includes('export async function receiveOriginalImageAsset(') &&
  store.includes('writeOriginalImageAssetBytes(database, arrival, null, false)') &&
  store.includes('assetAvailabilityHub.publish(result.storageHash, result.noteIds)'),
  'sync asset arrival writes then publishes availability');

console.log(`D02_ORIGINAL_IMAGE_LIFECYCLE_MATRIX_REPLAY_OK TOTAL=${total} FAILED=0`);
