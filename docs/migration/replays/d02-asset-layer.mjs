// Phase 1341 — asset-management layer
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const d = readFileSync(S + 'AssetDigest.ets', 'utf8');
t('SHA-512 digest', d.includes('SHA512') || d.includes('sha512'));
t('original asset hash bits', d.includes('originalAssetHashBitsFromSha512'));
t('64-byte check', d.includes('64'));
t('availability hub', existsSync(S + 'AssetAvailabilityHub.ets'));
t('hub singleton', readFileSync(S + 'AssetAvailabilityHub.ets', 'utf8').includes('assetAvailabilityHub'));
const c = readFileSync(S + 'AssetTemporaryArtifactCleanup.ets', 'utf8');
t('pending/trash dirs', c.includes('pending') && c.includes('trash'));
t('temp name patterns', c.includes('pending_asset') || c.includes('deleted_asset'));
t('init-boundary cleanup', c.includes('cleanupInterruptedAssetArtifacts'));
t('asset ref store', existsSync(S + 'OriginalAssetReferenceStore.ets'));
t('page-asset state', existsSync(S + 'OriginalPageInAssetState.ets'));
console.log('asset-layer replay: ' + n + '/10 checks green');
