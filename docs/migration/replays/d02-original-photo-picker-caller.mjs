import fs from 'node:fs';
const caller=fs.readFileSync('note/src/main/ets/data/OriginalPhotoPickerCaller.ets','utf8');
const ingress=fs.readFileSync('note/src/main/ets/data/OriginalPhotoIngress.ets','utf8');
const canvas=fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets','utf8');
const toolbar=fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets','utf8');
const page=fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets','utf8');
const base=JSON.parse(fs.readFileSync('note/src/main/resources/base/element/string.json','utf8'));
const zh=JSON.parse(fs.readFileSync('note/src/main/resources/zh_CN/element/string.json','utf8'));

function hasValue(json,name,value){ return json.string.some((entry) => entry.name===name && entry.value===value); }
const checks=[
 ['Harmony uses the current photoAccessHelper PhotoViewPicker API', caller.includes("@kit.MediaLibraryKit") && caller.includes('new photoAccessHelper.PhotoViewPicker()')],
 ['picker requests images and preserves ordered photoUris', caller.includes('PhotoViewMIMETypes.IMAGE_TYPE') && caller.includes('Array.from(result.photoUris)')],
 ['picker selection is validated before ingress import', caller.includes('validateOriginalPhotoSelection(uris)') && caller.includes('importOriginalPhotos(uris, request.cacheDirectory)')],
 ['selection and URI readers remain injectable for static tests', caller.includes('setOriginalPhotoUriListSelectorForTest') && ingress.includes('setOriginalPhotoUriReaderForTest')],
 ['canvas guards concurrent persistence and picker work', canvas.includes('@State photoImportBusy: boolean = false;') && canvas.includes('!this.historyBusy && !this.photoImportBusy')],
 ['canvas builds ordered plans with oriented intrinsic dimensions', canvas.includes('intrinsicWidth: item.orientedWidth') && canvas.includes('intrinsicHeight: item.orientedHeight') && canvas.includes('x: center.x + index * 24,')],
 ['multi-image commit reuses durable image insertion', canvas.includes('commitOriginalImageInsert') && canvas.includes('results[results.length - 1].elementOrder')],
 ['UI state updates only on the original loaded page generation', canvas.includes('generation === this.pageLoadGeneration && pageId === this.loadedPageId')],
 ['toolbar exposes Photo in expanded and compact menus', toolbar.includes("$r('app.string.insert_photo')") && toolbar.split("$r('app.string.insert_photo')").length >= 3],
 ['NotePage forwards the photo signal to NoteCanvasView', page.includes('@State photoInsertSignal: number = 0;') && page.includes('photoInsertSignal: this.photoInsertSignal')],
 ['localized labels and failure toast exist', hasValue(base,'insert_photo','Photo') && hasValue(zh,'insert_photo','图片') && hasValue(base,'original_photo_insert_failed',"Couldn't add photos") && hasValue(zh,'original_photo_insert_failed','无法添加图片')],
];
let failed=0;
for(const [name,passed] of checks){ console.log(`${passed?'PASS':'FAIL'} ${name}`); if(!passed)failed++; }
console.log(`D02_ORIGINAL_PHOTO_PICKER_CALLER_OK TOTAL=${checks.length} FAILED=${failed}`);
if(failed>0)process.exitCode=1;
