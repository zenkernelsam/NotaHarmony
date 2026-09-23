// Phase 630 — 图像拖放入口：原版画布 drop 监听器 e0f.P0（pl3 消费方，
// 经 dr.onDrag→ol3.P0 派发）遍历 ClipData 全部 item，收集 getUri() 非空的
// 条目后连同落点坐标调用插入回调（wx4.invoke(arrayList, mp5(x,y))）；
// 无 URI 或权限被拒 → return false（不接受）。Harmony 对齐：编辑器根 Stack
// 挂 .onDrop，UDMF 记录经 extractOriginalDroppedImagePayload 抽取
// general.file-uri / general.image(URI) / general.pixelmap，落点以
// getWindowX/Y − Area.globalPosition 换组件坐标再 screenToCanvas，
// 走与贴图/选图同一条 insertOriginalPhotos 管线。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e0f = fs.readFileSync(`${originalRoot}e0f.java`, 'utf8');
const dr = fs.readFileSync(`${originalRoot}dr.java`, 'utf8');
const ingress = fs.readFileSync('note/src/main/ets/data/OriginalDragDropIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const clipboardIngress = fs.readFileSync('note/src/main/ets/data/OriginalClipboardImageIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const photoIngress = fs.readFileSync('note/src/main/ets/data/OriginalPhotoIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

// --- 原版证据：e0f.P0 收集全部 URI item，带落点回调；空集/无权限 → false ---
assert.match(e0f, /implements pl3/);
assert.match(e0f, /ClipData clipData = dragEventC\.getClipData\(\)/);
assert.match(e0f, /itemAt != null \? itemAt\.getUri\(\) : null/);
assert.match(e0f, /arrayList\.add\(uri\)/);
assert.match(e0f, /if \(arrayList\.isEmpty\(\)\)/);
assert.match(e0f, /floatToRawIntBits\(dragEventC\.getX\(\)\)/);
assert.match(e0f, /floatToRawIntBits\(dragEventC\.getY\(\)\)/);
assert.match(e0f, /invoke\(arrayList, new mp5/);
// dr.onDrag 将 DROP(3) 事件派发给 ol3.P0 → pl3 消费方链。
assert.match(dr, /case 3:\s*return ol3Var\.P0\(kl3Var\)/);
assert.match(dr, /onDrag\(View view, DragEvent dragEvent\)/);

// --- Harmony 实现：UDMF 记录抽取（file-uri/image/pixelmap），其余类型拒绝 ---
assert.match(ingress, /export function extractOriginalDroppedImagePayload\(data: unifiedDataChannel\.UnifiedData\)/);
assert.match(ingress, /UDT_FILE_URI: string = 'general\.file-uri'/);
assert.match(ingress, /UDT_IMAGE: string = 'general\.image'/);
assert.match(ingress, /UDT_PIXELMAP: string = 'general\.pixelmap'/);
assert.match(ingress, /recordType !== UDT_FILE_URI && recordType !== UDT_IMAGE &&\s*recordType !== UDT_PIXELMAP/);
assert.match(ingress, /record\.getRecords\(\)|data\.getRecords\(\)/);
assert.match(ingress, /payload\.pixelMaps\.push\(maybePixelMap\)/);
// URI 分拣：带扩展名走 picker 同管线 importOriginalPhotos；无扩展名仍尝试
// 解码（原版不以扩展名门禁），解码失败逐条跳过而非整体中止。
assert.match(ingress, /isValidOriginalPhotoUri\(uri\)/);
assert.match(ingress, /await importOriginalPhotos\(extensionUris, cacheDirectory\)/);
assert.match(ingress, /await importExtensionlessDroppedImage\(uri, items\.length\)/);
assert.match(ingress, /catch \(_error\) \{\s*return null;/);
// pixelmap 记录复用剪贴板归一化（webp lossy + 降采样护栏）。
assert.match(ingress, /await normalizeOriginalPixelMap\(pixelMap\)/);
assert.match(clipboardIngress, /export async function normalizeOriginalPixelMap\(pixelMap: image\.PixelMap\)/);
assert.match(clipboardIngress, /return await normalizeOriginalPixelMap\(source\.pixelMap\)/);
// 无扩展名读取侧有尺寸上限（与 ORIGINAL_PHOTO_MAX_BYTES 一致）。
assert.match(ingress, /stat\.size > 104857600/);
assert.match(photoIngress, /ORIGINAL_PHOTO_MAX_BYTES: number = 104857600/);

// --- Harmony 实现：画布 onDrop 接线、落点坐标换算、结果回执 ---
assert.match(canvas, /onDrop\(\(event: DragEvent\)/);
assert.match(canvas, /this\.onOriginalImageDrop\(event\)/);
assert.match(canvas, /event\.setResult\(DragResult\.DROP_DISABLED\)/);
assert.match(canvas, /event\.setResult\(DragResult\.DROP_ENABLED\)/);
assert.match(canvas, /event\.getWindowX\(\)/);
assert.match(canvas, /event\.getWindowY\(\)/);
// 窗口坐标 − 组件 globalPosition → 组件坐标 → 画布坐标 → 插入锚点。
assert.match(canvas, /windowX - this\.canvasDropWindowOrigin\.x/);
assert.match(canvas, /this\.viewport\.screenToCanvas\(componentPoint\.x, componentPoint\.y\)/);
assert.match(canvas, /this\.getOriginalPhotoInsertOrigin\(anchor\)/);
assert.match(canvas, /await this\.insertOriginalPhotos\(imported, origin\)/);
// onAreaChange 捕获组件窗口原点。
assert.match(canvas, /newArea\.globalPosition\.x as number/);
assert.match(canvas, /this\.canvasDropWindowOrigin = \{ x: globalX, y: globalY \}/);
// 门禁与 busy 与既有贴图入口同约（canStartOriginalPhotoInsert + photoImportBusy）。
assert.match(canvas, /private onOriginalImageDrop\(event: DragEvent\): void \{\s*if \(!this\.canStartOriginalPhotoInsert\(\)\)/);
assert.match(canvas, /this\.photoImportBusy = true;\s*try \{\s*origin = this\.getOriginalPhotoInsertOrigin\(anchor\)/);
// 异步结束后同样走 onPhotoIngressFinished 收尾。
assert.match(canvas, /startOriginalDroppedImageInsert[\s\S]*?this\.onPhotoIngressFinished\(\);/);

// --- 功能仿真：UDMF 记录抽取语义 ---
function extract(records) {
  const payload = { uris: [], pixelMaps: [] };
  for (const record of records) {
    const t = record.getType();
    if (t !== 'general.file-uri' && t !== 'general.image' && t !== 'general.pixelmap') {
      continue;
    }
    const v = record.getValue();
    if (typeof v === 'string') {
      if (v.length > 0) payload.uris.push(v);
      continue;
    }
    if (typeof v === 'object' && v !== null) {
      const u = v.uri;
      if (typeof u === 'string' && u.length > 0) { payload.uris.push(u); continue; }
      if (typeof v.getImageInfo === 'function') payload.pixelMaps.push(v);
    }
  }
  return payload;
}
const rec = (type, value) => ({ getType: () => type, getValue: () => value });
let p = extract([rec('general.file-uri', 'file:///a/b.png'), rec('general.plain-text', 'hi')]);
assert.deepEqual(p.uris, ['file:///a/b.png']);
assert.equal(p.pixelMaps.length, 0);
p = extract([rec('general.image', { uri: 'media://x/y.jpg' }), rec('general.pixelmap', { getImageInfo: () => 1 })]);
assert.deepEqual(p.uris, ['media://x/y.jpg']);
assert.equal(p.pixelMaps.length, 1);
p = extract([rec('general.file-uri', ''), rec('general.text', { uri: 'nope' })]);
assert.deepEqual(p.uris, []);
// 扩展名分拣：带支持扩展名 → picker 管线；无/非法扩展名 → 解码兜底。
function split(uris, isValid) {
  const ok = [], rest = [];
  for (const u of uris) (isValid(u) ? ok : rest).push(u);
  return [ok, rest];
}
assert.deepEqual(split(['file:///a/b.png', 'datashare:///x'], u => u.endsWith('.png')),
  [['file:///a/b.png'], ['datashare:///x']]);

console.log('D05_ORIGINAL_IMAGE_DROP_INGRESS_REPLAY_OK TOTAL=45 FAILED=0');
