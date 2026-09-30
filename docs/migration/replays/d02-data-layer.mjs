// Phase 1283 — com.gingerlabs.notability data-layer census
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('NoteAsset DB+workers', X('data/note/assets/NoteAssetDatabase.java') && X('data/note/assets/NoteAssetUploadWorker.java'));
t('synced-op exceptions', X('data/note/ops/synced/CorruptedSyncedOpException.java') && X('data/note/ops/synced/StaleSyncedNoteException.java'));
t('NoteState+BundleMeta DB', X('data/note/state/NoteStateDatabase.java') && X('data/note/ops/database/NoteBundleMetadataDatabase.java'));
t('library ntb+MissingAssets', X('data/library/state/ntb/MissingAssetsException.java'));
t('Learn+Search+Settings+Toolbox+Transcription DBs', X('data/learn/database/LearnDatabase.java') && X('data/search/database/SearchDatabase.java') && X('data/settings/database/SettingsDatabase.java') && X('data/toolbar/database/ToolboxDatabase.java') && X('data/transcription/database/TranscriptionDatabase.java'));
t('transcription GCS upload', X('data/transcription/upload/GCSUploadException.java'));
t('billing+samsungbilling', X('data/billing/client/PlayBillingClient$BillingException.java') && X('data/samsungbilling/client/SamsungBillingClient$SamsungBillingException.java'));
t('core glmath native', X('core/glmath/GLMathNative.java') && X('core/glmath/GLMathTextMeasurer.java'));
t('core shared-mem+retrofit+network', X('core/common/memory/SharedMemoryByteArena$ArenaClosedException.java') && X('core/retrofit/HttpFailureException.java') && X('core/network/NoConnectivityException.java'));
const ma = R('app/MainActivity.java'), nb = R('app/NbApplication.java');
t('MainActivity+NbApplication', ma.length > 0 && nb.length > 0);
console.log('data-layer replay: ' + n + '/10 checks green');
