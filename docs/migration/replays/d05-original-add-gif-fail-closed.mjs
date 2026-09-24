// D05 原版「Add GIF」Klipy 联网挑选 fail-closed 登记 — Phase 659
// 证据：docs/migration/evidence/original-add-gif-klipy-jadx-2026-09-24.md
// 原版 add_gif 是 qc 插入菜单第 4 项（function4!=null 条件渲染），由
// ac4.k0=ANIMATED_IMAGES 特性旗标门控；picker 走 Klipy SaaS
//（f65 内嵌 api.klipy.com 客户密钥），选中 p55 GifItem 后 re0 下载到
// 临时文件（104857600B=100MB 上限）→ je4 FileInfo → bgj.b 落 cz0.IMAGE
// 元素。Harmony 无 Klipy SDK、不可复制厂商密钥，登记 fail-closed。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

const qc = read(`${SRC}/defpackage/qc.java`);
const ac4 = read(`${SRC}/ac4.java`.replace('/ac4.java', '/defpackage/ac4.java'));
const u49 = read(`${SRC}/defpackage/u49.java`);
const f65 = read(`${SRC}/defpackage/f65.java`);
const p55 = read(`${SRC}/defpackage/p55.java`);
const re0 = read(`${SRC}/defpackage/re0.java`);
const bgj = read(`${SRC}/defpackage/bgj.java`);
const ar4 = read(`${SRC}/defpackage/ar4.java`);
const u22 = read(`${SRC}/defpackage/u22.java`);

const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const strBase = read('note/src/main/resources/base/element/string.json');
const strZh = read('note/src/main/resources/zh_CN/element/string.json');

// --- 原版：add_gif 是条件菜单项，由 ANIMATED_IMAGES 旗标门控 ---
check(qc.includes('feature_note_toolbox__add_gif') &&
  qc.includes('function4 != null'),
  'qc renders add_gif only when function4 is non-null');
check(ac4.includes('"ANIMATED_IMAGES"'),
  'ac4.k0 is the ANIMATED_IMAGES feature flag');
check(u49.includes('ac4.k0') && u49.includes('new qb5(gl8Var10, 23)'),
  'u49 gates the gif callback behind ac4.k0 and opens the picker sheet');

// --- 原版：Klipy SaaS 依赖 ---
check(f65.includes('api.klipy.com/api/v1/') && f65.includes('/gifs/'),
  'f65 builds Klipy gif-search URLs');
check(f65.includes('per_page=') && f65.includes('&q=') && f65.includes('locale='),
  'f65 query carries per_page/locale/q search params');
check(/api\.klipy\.com\/api\/v1\/[A-Za-z0-9]{60,}\/gifs/.test(f65),
  'f65 embeds a vendor Klipy customer key in the URL path');
check(u22.includes('gif_picker_search_hint') || u22.includes('search_hint'),
  'u22 hosts the gif search field');
check(ar4.includes('gif_picker_item_description') &&
  ar4.includes('new gd2(ix4Var2, p55Var'),
  'ar4 renders GifItem grid cells invoking the pick callback');

// --- 原版：选中 → 下载 → IMAGE 元素 ---
check(p55.includes('GifItem(previewUrl=') && p55.includes('fullUrl='),
  'p55 GifItem carries previewUrl/fullUrl/width/height');
check(re0.includes('File.createTempFile("gif_", ".gif"') &&
  re0.includes('104857600'),
  're0 downloads the gif to a temp file with the 100MB insert cap');
check(re0.includes('GIF exceeded max insert size'),
  'oversized gifs abort with the max-size message');
check(re0.includes('new je4(name, "image/gif"'),
  're0 wraps the file as je4 FileInfo with image/gif mime');
check(bgj.includes('cz0Var2 = cz0.IMAGE') || bgj.includes('cz0.IMAGE'),
  'bgj.b materializes the picked gif as a cz0.IMAGE element');

// --- Harmony：无 Klipy 表面（结构性 fail-closed） ---
check(!toolbar.includes('add_gif') && !strBase.includes('add_gif') &&
  !strZh.includes('add_gif'),
  'Harmony insert menu has no add_gif item or strings');
check(!/klipy/i.test(importer) && !/klipy/i.test(toolbar),
  'Harmony sources carry no Klipy integration');
check(importer.includes("'.gif'"),
  'local .gif files still import via Add Files as image elements (P653/P657)');

console.log(`D05_ORIGINAL_ADD_GIF_FAIL_CLOSED_REPLAY_OK TOTAL=${total} FAILED=0`);
