import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const adr = read('docs/migration/adr/ADR-0693-original-design-system-typography-failclosed.md');
const evidence = read('docs/migration/evidence/original-design-system-typography-jadx-2026-09-25.md');
const noteFonts = read('note/src/main/ets/data/NoteFonts.ets');

// 边界登记 pin：ADR 登记四族商业字体 fail-closed。
assert.match(adr, /GT Flaire/);
assert.match(adr, /Untitled Serif/);
assert.match(adr, /Proxima Soft/);
assert.match(adr, /GT America Mono/);
assert.match(adr, /商业许可/);
// 证据文档 pin：ar8 注册表 + bv8 主题槽位 + taa 15 样式。
assert.match(evidence, /ar8\.java/);
assert.match(evidence, /bv8/);
assert.match(evidence, /taa\.java/);
assert.match(evidence, /gtflairebasic_black/);
assert.match(evidence, /untitledserif_\{regular/);
assert.match(evidence, /proximasoft_\{regular/);
assert.match(evidence, /gtamericamono_bold/);
// 笔记内容字体仍只注册开源三族（未被本边界波及）。
assert.match(noteFonts, /familyName: 'Inter'/);
assert.match(noteFonts, /familyName: 'Roboto'/);
assert.match(noteFonts, /familyName: 'EBGaramond'/);
assert.doesNotMatch(noteFonts, /GTFlaire|UntitledSerif|ProximaSoft|GTAmericaMono/);

console.log('D02_ORIGINAL_DESIGN_SYSTEM_TYPOGRAPHY_OK ' +
  'adr-pins=5|evidence-pins=6|note-fonts-open-only=4');
