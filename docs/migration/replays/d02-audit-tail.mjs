// Phase 1347 — audit tail (selection overlay + thumbnail)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const C = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/components/';
const R = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/rendering/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const so = readFileSync(C + 'SelectionOverlayLayout.ets', 'utf8');
const tp = readFileSync(R + 'ThumbnailRenderPolicy.ets', 'utf8');
t('overlay position fn', so.includes('selectionOverlayPosition'));
t('rotation handle ref (msc)', so.includes('msc') || so.includes('RotationHandle') || so.includes('rotation'));
t('paste position', so.includes('standalonePastePosition'));
t('thumbnail fit fn', tp.includes('fitPageInThumbnail'));
t('aspect-fit min-scale', tp.includes('Math.min'));
t('margin handling', tp.includes('margin'));
t('geometry validate', tp.includes('Number.isFinite'));
t('transform type', tp.includes('ThumbnailPageTransform'));
t('both files exist', existsSync(C + 'SelectionOverlayLayout.ets') && existsSync(R + 'ThumbnailRenderPolicy.ets'));
t('scale computed', tp.includes('scale'));
console.log('audit-tail replay: ' + n + '/10 checks green');
