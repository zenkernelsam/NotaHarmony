import assert from 'node:assert/strict';
import fs from 'node:fs';

const caller = fs.readFileSync('note/src/main/ets/data/OriginalPhotoPickerCaller.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const sdk = fs.readFileSync(
  'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/api/@ohos.file.photoAccessHelper.d.ts',
  'utf8').replaceAll('\r\n', '\n');

assert.match(sdk, /class PhotoSelectOptions extends BaseSelectOptions \{/);
assert.match(sdk, /maxSelectNumber\?: number;/);
assert.match(sdk, /photoUris: Array<string>;/);
const originalIndex = sdk.indexOf('isOriginalPhoto: boolean;');
assert.ok(originalIndex > sdk.indexOf('photoUris: Array<string>;'));
assert.match(sdk, /Whether the selected media asset is the original image\./);

assert.match(caller, /export const ORIGINAL_PHOTO_PICKER_MAX_SELECTION: number = 500;/);
assert.match(caller, /options\.MIMEType = photoAccessHelper\.PhotoViewMIMETypes\.IMAGE_TYPE;/);
assert.equal(caller.includes('options.maxSelectNumber = 500;'), false);
assert.match(caller,
  /options\.maxSelectNumber = ORIGINAL_PHOTO_PICKER_MAX_SELECTION;\s+const result: photoAccessHelper\.PhotoSelectResult = await picker\.select\(options\);\s+if \(!result\.isOriginalPhoto\) \{\s+throw new Error\('photo picker returned a non-original image'\);\s+\}\s+return Array\.from\(result\.photoUris\);/);
assert.match(caller, /validateOriginalPhotoSelection\(uris\)/);
assert.match(caller, /importOriginalPhotos\(uris, request\.cacheDirectory\)/);

console.log('D02_PHOTO_PICKER_ORIGINAL_ASSET_BOUND_REPLAY_OK TOTAL=9 FAILED=0');
